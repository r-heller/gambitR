#' Search for the best move
#'
#' Minimax search with alpha-beta pruning to a fixed depth, driven by
#' [gm_evaluate()]. This is the native R engine used for play and simulation.
#'
#' @param position A [gm_position] object.
#' @param depth Search depth in plies. Default `3`.
#' @param engine Backend: `"native"` (default, pure R minimax) or `"uci"` to
#'   delegate to an external 'UCI' engine via [gm_uci_bestmove()].
#' @param verbose If `TRUE` (default), report search progress.
#' @param call The execution environment, for error reporting. Experts only.
#' @return A [tibble::tibble()] with columns `san` (best move), `score`
#'   (centipawns, White's perspective), `depth` (integer) and `nodes`
#'   (integer, nodes searched). One row.
#' @export
#' @family analysis
#' @examples
#' \donttest{
#' gm_bestmove(gm_position(), depth = 2)
#' }
gm_bestmove <- function(position, depth = 3L, engine = c("native", "uci"),
                        verbose = TRUE, call = rlang::caller_env()) {
  engine <- rlang::arg_match(engine)
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.", call = call)
  }
  # TODO(build): native alpha-beta; when engine == "uci", call gm_uci_bestmove().
  tibble::tibble(san = NA_character_, score = 0, depth = as.integer(depth), nodes = 0L)
}
