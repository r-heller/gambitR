#' Query a 'UCI' engine for the best move
#'
#' Optional deeper analysis backend. Requires the \pkg{processx} package and an
#' external 'UCI' engine binary (e.g. 'Stockfish') on the system. Falls back
#' with an informative error when either is unavailable.
#'
#' The engine is driven through the standard handshake: `uci` until `uciok`,
#' `isready` until `readyok`, then `position fen ...` and `go movetime ...`
#' until `bestmove`. Scores are reported from White's perspective, matching
#' [gm_evaluate()], and a forced mate is reported as a score of
#' `100000 - plies`. The engine process is always shut down, including when
#' the call errors.
#'
#' @param position A [gm_position] object.
#' @param engine_path Path to a 'UCI' engine binary. If `NULL` (default),
#'   `gambitR` looks on the `PATH` for `stockfish`.
#' @param movetime Search time in milliseconds. Default `1000`.
#' @param verbose If `TRUE` (default), report engine info lines.
#' @param call The execution environment, for error reporting. Experts only.
#' @return A [tibble::tibble()] with columns `san`, `score` and `pv`
#'   (principal variation string). One row.
#' @export
#' @family analysis
#' @examplesIf requireNamespace("processx", quietly = TRUE) && nzchar(Sys.which("stockfish"))
#' gm_uci_bestmove(gm_position())
gm_uci_bestmove <- function(position, engine_path = NULL, movetime = 1000L,
                            verbose = TRUE, call = rlang::caller_env()) {
  info <- .gm_uci_query(
    position,
    engine_path = engine_path, movetime = movetime,
    verbose = verbose, call = call
  )
  tibble::tibble(san = info$san, score = info$score, pv = info$pv)
}

# The full engine query. `gm_uci_bestmove()` exposes part of this; the "uci"
# backend of `gm_bestmove()` uses the depth and node counts as well.
#' @noRd
.gm_uci_query <- function(position, engine_path = NULL, movetime = 1000L,
                          verbose = TRUE, call = rlang::caller_env(), depth = NULL) {
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.", call = call)
  }
  if (!requireNamespace("processx", quietly = TRUE)) {
    cli::cli_abort(c(
      "Package {.pkg processx} is required for {.fn gm_uci_bestmove}.",
      "i" = "Install it with {.code install.packages('processx')}."
    ), call = call)
  }
  if (!is.numeric(movetime) || length(movetime) != 1L || !is.finite(movetime) ||
    movetime <= 0 || movetime != trunc(movetime) || movetime > .Machine$integer.max) {
    cli::cli_abort("{.arg movetime} must be a single positive whole number.", call = call)
  }
  engine_path <- engine_path %||% unname(Sys.which("stockfish"))
  if (!nzchar(engine_path)) {
    cli::cli_abort(c(
      "No 'UCI' engine found.",
      "i" = "Install {.emph Stockfish} or pass {.arg engine_path}."
    ), call = call)
  }
  movetime <- as.integer(movetime)
  fen <- gm_write_fen(position)

  proc <- processx::process$new(
    engine_path,
    stdin = "|", stdout = "|", stderr = "|"
  )
  on.exit(
    {
      if (proc$is_alive()) {
        try(proc$write_input("quit\n"), silent = TRUE)
        proc$kill()
      }
    },
    add = TRUE
  )

  say <- function(x) proc$write_input(paste0(x, "\n"))
  listen <- function(pattern, timeout) {
    deadline <- Sys.time() + timeout / 1000
    collected <- character(0L)
    repeat {
      if (!proc$is_alive() && !proc$is_incomplete_output()) break
      proc$poll_io(200L)
      new <- proc$read_output_lines()
      if (length(new)) {
        collected <- c(collected, new)
        if (verbose) {
          for (line in new[grepl("^info .*\\bdepth\\b", new)]) {
            cli::cli_alert_info(line)
          }
        }
        if (any(grepl(pattern, new))) break
      }
      if (Sys.time() > deadline) break
    }
    collected
  }

  say("uci")
  handshake <- listen("^uciok", 10000L)
  if (!any(grepl("^uciok", handshake))) {
    cli::cli_abort(c(
      "The engine at {.path {engine_path}} did not complete the 'UCI' handshake.",
      "i" = "Expected a {.code uciok} reply."
    ), call = call)
  }
  say("isready")
  if (!any(grepl("^readyok", listen("^readyok", 10000L)))) {
    cli::cli_abort("The engine did not reply {.code readyok}.", call = call)
  }
  say(paste0("position fen ", fen))
  command <- paste0("go movetime ", movetime)
  if (!is.null(depth)) command <- paste(command, "depth", depth)
  say(command)
  output <- listen("^bestmove", as.double(movetime) + 10000)

  bestmove_line <- grep("^bestmove", output, value = TRUE)
  if (!length(bestmove_line)) {
    cli::cli_abort("The engine did not return a {.code bestmove}.", call = call)
  }
  lan <- sub("^bestmove\\s+(\\S+).*$", "\\1", bestmove_line[[1L]])
  info_lines <- grep("^info .*\\bscore\\b", output, value = TRUE)
  last_info <- if (length(info_lines)) info_lines[[length(info_lines)]] else NA_character_
  parsed <- .gm_parse_uci_info(last_info)
  san <- .gm_lan_to_san(position, lan)
  score <- parsed$score
  if (!is.na(score) && position$turn == "b") score <- -score
  tibble::tibble(
    san = san,
    score = score,
    pv = parsed$pv,
    depth = parsed$depth,
    nodes = parsed$nodes
  )
}

# Pull the score, depth, node count and principal variation out of the last
# `info` line the engine emitted.
#' @noRd
.gm_parse_uci_info <- function(line) {
  empty <- list(
    score = NA_real_, depth = NA_integer_, nodes = NA_integer_, pv = NA_character_
  )
  if (is.na(line)) {
    return(empty)
  }
  field <- function(pattern) {
    m <- regmatches(line, regexpr(pattern, line))
    if (!length(m)) NA_character_ else sub(pattern, "\\1", m)
  }
  cp <- field("score cp (-?[0-9]+)")
  mate <- field("score mate (-?[0-9]+)")
  score <- if (!is.na(cp)) {
    as.numeric(cp)
  } else if (!is.na(mate)) {
    sign(as.numeric(mate)) * (.GM_MATE_SCORE - abs(as.numeric(mate)) * 2)
  } else {
    NA_real_
  }
  depth <- field("depth ([0-9]+)")
  nodes <- field("nodes ([0-9]+)")
  pv <- field("\\bpv (.*)$")
  list(
    score = score,
    depth = if (is.na(depth)) NA_integer_ else as.integer(depth),
    nodes = if (is.na(nodes)) NA_integer_ else as.integer(nodes),
    pv = if (is.na(pv)) NA_character_ else trimws(pv)
  )
}

# Convert an engine's long algebraic move to standard algebraic notation.
#' @noRd
.gm_lan_to_san <- function(position, lan) {
  if (is.na(lan) || !nzchar(lan) || identical(lan, "(none)")) {
    return(NA_character_)
  }
  st <- .gm_state(position)
  mv <- .gm_gen_legal(st)
  i <- match(tolower(lan), .gm_lan_all(mv))
  if (is.na(i)) {
    return(NA_character_)
  }
  .gm_san_all(st, mv)[[i]]
}

#' @noRd
.gm_has_uci <- function() {
  requireNamespace("processx", quietly = TRUE) && nzchar(Sys.which("stockfish"))
}
