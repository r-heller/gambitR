#' Evaluate a position
#'
#' Static heuristic evaluation from White's perspective: material balance plus
#' piece-square tables, mobility and simple king-safety terms. Positive favours
#' White, negative favours Black, in centipawns.
#'
#' @param position A [gm_position] object.
#' @param weights A named list of term weights. If `NULL` (default), package
#'   defaults are used.
#' @return A length-1 numeric score in centipawns.
#' @export
#' @family analysis
#' @examples
#' gm_evaluate(gm_position())
gm_evaluate <- function(position, weights = NULL) {
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.")
  }
  # TODO(build): material + PST + mobility; weights %||% .gm_default_weights().
  0
}

#' @noRd
.gm_default_weights <- function() {
  list(material = 1, mobility = 0.1, king_safety = 0.2)
}
