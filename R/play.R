.GM_TERMINATIONS <- c(
  "checkmate", "stalemate", "fifty-move", "threefold",
  "insufficient material", "move limit"
)

#' Play a full game between two strategies
#'
#' Run a self-play game from a starting position until termination, with each
#' side driven by a strategy function.
#'
#' A game ends on checkmate, stalemate, the fifty-move rule, threefold
#' repetition, insufficient mating material, or when `max_moves` full moves
#' have been played, in which case the game is adjudicated as a draw. The
#' termination reason is recorded in the game's `Termination` tag.
#'
#' @param white,black Strategy functions. Each takes a [gm_position] and
#'   returns a single move in standard algebraic notation. Defaults to the
#'   native engine at depth 2. Character shortcuts `"random"` and `"engine"`
#'   are also accepted.
#' @param position Starting [gm_position]. Default is the standard start.
#' @param max_moves Maximum full moves before adjudication. Default `200`.
#' @param verbose If `TRUE` (default), report each move.
#' @return A [gm_game] object.
#' @export
#' @family play
#' @examples
#' \donttest{
#' gm_play(white = "random", black = "random", max_moves = 10, verbose = FALSE)
#' }
gm_play <- function(white = "engine", black = "engine", position = NULL,
                    max_moves = 200L, verbose = TRUE) {
  position <- position %||% gm_position()
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.")
  }
  if (!is.numeric(max_moves) || length(max_moves) != 1L || !is.finite(max_moves) ||
    max_moves < 1 || max_moves != trunc(max_moves) || max_moves > .Machine$integer.max) {
    cli::cli_abort("{.arg max_moves} must be a single positive whole number.")
  }
  max_moves <- as.integer(max_moves)
  players <- list(
    w = .gm_strategy(white, arg = "white"),
    b = .gm_strategy(black, arg = "black")
  )
  labels <- list(w = .gm_strategy_label(white), b = .gm_strategy_label(black))

  moves <- character(0L)
  positions <- list(position)
  seen <- c(.gm_repetition_key(position))
  current <- position
  termination <- "move limit"
  repeat {
    status <- gm_status(current)
    if (status == "checkmate") {
      termination <- "checkmate"
      break
    }
    if (status == "stalemate") {
      termination <- "stalemate"
      break
    }
    if (current$halfmove >= 100L) {
      termination <- "fifty-move"
      break
    }
    if (.gm_insufficient_material(current)) {
      termination <- "insufficient material"
      break
    }
    if (max(table(seen)) >= 3L) {
      termination <- "threefold"
      break
    }
    if (length(moves) >= 2 * as.double(max_moves)) {
      termination <- "move limit"
      break
    }
    mover <- current$turn
    move <- players[[mover]](current)
    if (!is.character(move) || length(move) != 1L || is.na(move)) {
      cli::cli_abort(c(
        "The {mover} strategy must return a single move as a string.",
        "x" = "It returned {.obj_type_friendly {move}}."
      ))
    }
    current <- gm_move(current, move)
    moves <- c(moves, move)
    positions <- c(positions, list(current))
    seen <- c(seen, .gm_repetition_key(current))
    if (verbose) {
      cli::cli_alert_info(
        "{(length(moves) + 1L) %/% 2L}{if (mover == 'w') '.' else '...'} {move}"
      )
    }
  }
  result <- .gm_result(current, termination)
  if (verbose) {
    cli::cli_alert_success(
      "{result} after {length(moves)} half-move{?s} ({termination})."
    )
  }
  new_gm_game(
    moves = moves,
    positions = positions,
    tags = list(
      Event = "gambitR self-play", Site = "gambitR",
      Date = format(Sys.Date(), "%Y.%m.%d"), Round = "1",
      White = labels$w, Black = labels$b,
      Result = result, Termination = termination
    ),
    result = result
  )
}

#' @noRd
.gm_result <- function(position, termination) {
  if (termination == "checkmate") {
    if (position$turn == "w") "0-1" else "1-0"
  } else {
    "1/2-1/2"
  }
}

# Resolve a strategy shortcut or validate a user-supplied function.
#' @noRd
.gm_strategy <- function(x, arg, call = rlang::caller_env()) {
  if (is.function(x)) {
    return(x)
  }
  if (is.character(x) && length(x) == 1L && !is.na(x)) {
    return(switch(x,
      random = function(position) {
        moves <- gm_legal_moves(position)$san
        moves[[sample.int(length(moves), 1L)]]
      },
      engine = function(position) {
        gm_bestmove(position, depth = 2L, verbose = FALSE)$san
      },
      cli::cli_abort(c(
        "Unknown strategy {.val {x}} for {.arg {arg}}.",
        "i" = "Use {.val random}, {.val engine} or a function."
      ), call = call)
    ))
  }
  cli::cli_abort(
    "{.arg {arg}} must be a function, {.val random} or {.val engine}.",
    call = call
  )
}

#' @noRd
.gm_strategy_label <- function(x) {
  if (is.character(x) && length(x) == 1L && !is.na(x)) x else "custom"
}

# Repetition is judged on placement, side to move, castling rights and the en
# passant square, exactly as the threefold rule requires.
#' @noRd
.gm_repetition_key <- function(position) {
  # FIDE 9.2.3: an en-passant target distinguishes positions only when
  # a legal capture is available, including the king-safety restriction.
  ep <- "-"
  if (!is.na(position$ep) && any(.gm_gen_legal(.gm_state(position))$flag == 3L))
    ep <- position$ep
  paste(paste(position$board, collapse = ""), position$turn,
        position$castling, ep)
}

# King versus king, and king and a single minor piece versus king, cannot be
# mated. Anything richer is left to play out.
#' @noRd
.gm_insufficient_material <- function(position) {
  pieces <- position$board[position$board != "."]
  pieces <- pieces[!pieces %in% c("K", "k")]
  if (length(pieces) == 0L) {
    return(TRUE)
  }
  length(pieces) == 1L && pieces %in% c("N", "n", "B", "b")
}

#' Simulate many games between strategies
#'
#' Batch tournament driver: play `n` games between two strategies and return a
#' tidy summary of outcomes.
#'
#' @param white,black Strategy functions or shortcuts, as in [gm_play()].
#' @param n Number of games. Default `10`.
#' @param max_moves Maximum full moves per game. Default `200`.
#' @param verbose If `TRUE` (default), show a progress bar.
#' @return A [tibble::tibble()] with one row per game and columns `game`
#'   (integer), `result` (`"1-0"`, `"0-1"`, `"1/2-1/2"`), `plies` (integer)
#'   and `termination` (character).
#' @export
#' @family play
#' @examples
#' \donttest{
#' gm_simulate(white = "random", black = "random", n = 3, max_moves = 20, verbose = FALSE)
#' }
gm_simulate <- function(white = "random", black = "random", n = 10L,
                        max_moves = 200L, verbose = TRUE) {
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n < 1 ||
      n != trunc(n) || n > .Machine$integer.max) {
    cli::cli_abort("{.arg n} must be a single positive whole number.")
  }
  n <- as.integer(n)
  result <- character(n)
  plies <- integer(n)
  termination <- character(n)
  if (verbose) {
    cli::cli_progress_bar("Simulating games", total = n, .envir = rlang::current_env())
  }
  for (i in seq_len(n)) {
    game <- gm_play(
      white = white, black = black,
      max_moves = max_moves, verbose = FALSE
    )
    result[[i]] <- game$result
    plies[[i]] <- length(game$moves)
    termination[[i]] <- game$tags[["Termination"]] %||% NA_character_
    if (verbose) cli::cli_progress_update(.envir = rlang::current_env())
  }
  tibble::tibble(
    game = seq_len(n),
    result = result,
    plies = plies,
    termination = termination
  )
}
