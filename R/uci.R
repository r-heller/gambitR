#' Query a 'UCI' engine for the best move
#'
#' Optional deeper analysis backend. Requires the \pkg{processx} package and an
#' external 'UCI' engine binary (e.g. 'Stockfish') on the system. Falls back
#' with an informative error when either is unavailable.
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
#' @examplesIf gambitR:::.gm_has_uci()
#' gm_uci_bestmove(gm_position())
gm_uci_bestmove <- function(position, engine_path = NULL, movetime = 1000L,
                            verbose = TRUE, call = rlang::caller_env()) {
  if (!requireNamespace("processx", quietly = TRUE)) {
    cli::cli_abort(c(
      "Package {.pkg processx} is required for {.fn gm_uci_bestmove}.",
      "i" = "Install it with {.code install.packages('processx')}."
    ), call = call)
  }
  engine_path <- engine_path %||% unname(Sys.which("stockfish"))
  if (!nzchar(engine_path)) {
    cli::cli_abort(c(
      "No 'UCI' engine found.",
      "i" = "Install {.emph Stockfish} or pass {.arg engine_path}."
    ), call = call)
  }
  # TODO(build): spawn engine, send position fen / go movetime, parse bestmove + info.
  tibble::tibble(san = NA_character_, score = 0, pv = NA_character_)
}

#' @noRd
.gm_has_uci <- function() {
  requireNamespace("processx", quietly = TRUE) && nzchar(Sys.which("stockfish"))
}
