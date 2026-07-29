#' @noRd
.gm_empty_puzzles <- function() {
  tibble::tibble(
    id = character(0L), fen = character(0L), solution = list(),
    theme = character(0L), rating = integer(0L)
  )
}

#' @noRd
.gm_puzzle_set <- function() {
  .gm_extdata("puzzles.rds", .gm_empty_puzzles())
}

#' Load a tactical puzzle
#'
#' Draw a puzzle from the bundled set: a position with a known best move or
#' mating sequence.
#'
#' The set ships as `inst/extdata/puzzles.rds` and is built by
#' `data-raw/puzzles.R`, which checks every solution against the move
#' generator: each move must be legal in turn, every forced reply must be the
#' opponent's only legal move, and any line ending in `#` must really end in
#' checkmate.
#'
#' @param id Puzzle id, or `NULL` (default) to draw at random.
#' @param theme Optional theme filter (e.g. `"fork"`, `"mateIn2"`).
#' @param seed Optional integer seed for reproducible random draws.
#' @return A `gm_puzzle` object: a list with `position` ([gm_position]),
#'   `solution` (character vector of SAN moves), `theme` and `rating`.
#' @export
#' @family puzzles
#' @examples
#' p <- gm_puzzle(seed = 1)
#' p$theme
#' p$solution
#'
#' gm_puzzle(id = "gm-0001")$solution
gm_puzzle <- function(id = NULL, theme = NULL, seed = NULL) {
  if (!is.null(seed)) withr_local_seed(seed)
  set <- .gm_puzzle_set()
  if (nrow(set) == 0L) {
    cli::cli_abort("The bundled puzzle set could not be loaded.")
  }
  if (!is.null(id)) {
    if (!is.character(id) || length(id) != 1L || is.na(id)) {
      cli::cli_abort("{.arg id} must be a single non-NA string or {.code NULL}.")
    }
    known <- .gm_puzzle_set()$id
    set <- set[set$id == id, , drop = FALSE]
    if (nrow(set) == 0L) {
      cli::cli_abort(c(
        "No puzzle with id {.val {id}}.",
        "i" = "Known ids are {.val {known}}."
      ))
    }
  }
  if (!is.null(theme)) {
    if (!is.character(theme) || length(theme) != 1L || is.na(theme)) {
      cli::cli_abort("{.arg theme} must be a single non-NA string or {.code NULL}.")
    }
    themes <- sort(unique(.gm_puzzle_set()$theme))
    set <- set[set$theme == theme, , drop = FALSE]
    if (nrow(set) == 0L) {
      cli::cli_abort(c(
        "No puzzle with theme {.val {theme}}.",
        "i" = "Available themes are {.val {themes}}."
      ))
    }
  }
  i <- if (nrow(set) == 1L) 1L else sample.int(nrow(set), 1L)
  new_gm_puzzle(
    id = set$id[[i]],
    position = gm_read_fen(set$fen[[i]]),
    solution = set$solution[[i]],
    theme = set$theme[[i]],
    rating = set$rating[[i]]
  )
}

#' @noRd
new_gm_puzzle <- function(id, position, solution, theme, rating) {
  structure(
    list(
      id = id, position = position, solution = solution,
      theme = theme, rating = rating
    ),
    class = "gm_puzzle"
  )
}

#' @export
print.gm_puzzle <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_text(
    "{.cls gm_puzzle} {.val {x$id}} \u2014 theme {.val {x$theme}}, rating {.val {x$rating}}"
  )
  cli::cli_text(
    "{.field {if (x$position$turn == 'w') 'White' else 'Black'}} to move, {length(x$solution)} move{?s} to find"
  )
  cli::cli_verbatim(.gm_format_board(x$position))
  invisible(x)
}

#' Check a puzzle solution attempt
#'
#' @param puzzle A `gm_puzzle` object, as returned by [gm_puzzle()].
#' @param moves A character vector of attempted moves in standard algebraic
#'   notation.
#' @return A one-row [tibble::tibble()] with `correct` (logical), `solved_plies`
#'   (integer, how many correct moves matched) and `total_plies` (integer).
#' @export
#' @family puzzles
#' @examples
#' p <- gm_puzzle(id = "gm-0001")
#' gm_check_solution(p, character())
#' gm_check_solution(p, p$solution)
gm_check_solution <- function(puzzle, moves) {
  if (!inherits(puzzle, "gm_puzzle")) {
    cli::cli_abort("{.arg puzzle} must be a {.cls gm_puzzle} object.")
  }
  if (!is.character(moves)) {
    cli::cli_abort("{.arg moves} must be a character vector of moves.")
  }
  solution <- puzzle$solution
  total <- length(solution)
  matched <- 0L
  for (i in seq_along(moves)) {
    if (i > total) break
    if (!identical(.gm_bare_san(moves[[i]]), .gm_bare_san(solution[[i]]))) break
    matched <- matched + 1L
  }
  tibble::tibble(
    correct = matched == total && length(moves) >= total,
    solved_plies = matched,
    total_plies = as.integer(total)
  )
}

#' @noRd
withr_local_seed <- function(seed, .local_envir = parent.frame()) {
  if (requireNamespace("withr", quietly = TRUE)) {
    withr::local_seed(seed, .local_envir = .local_envir)
  } else {
    set.seed(seed)
  }
}
