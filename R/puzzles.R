#' Load a tactical puzzle
#'
#' Draw a puzzle from the bundled set: a position with a known best move or
#' mating sequence.
#'
#' @param id Puzzle id, or `NULL` (default) to draw at random.
#' @param theme Optional theme filter (e.g. `"fork"`, `"mateIn2"`).
#' @param seed Optional integer seed for reproducible random draws.
#' @return A [gm_puzzle] object: a list with `position` ([gm_position]),
#'   `solution` (character vector of SAN moves), `theme` and `rating`.
#' @export
#' @family puzzles
#' @examples
#' gm_puzzle(seed = 1)
gm_puzzle <- function(id = NULL, theme = NULL, seed = NULL) {
  if (!is.null(seed)) withr_local_seed(seed)
  # TODO(build): load inst/extdata/puzzles.rds, filter, sample.
  structure(
    list(position = gm_position(), solution = character(),
         theme = NA_character_, rating = NA_integer_),
    class = "gm_puzzle"
  )
}

#' Check a puzzle solution attempt
#'
#' @param puzzle A [gm_puzzle] object.
#' @param moves A character vector of attempted moves in standard algebraic
#'   notation.
#' @return A one-row [tibble::tibble()] with `correct` (logical), `solved_plies`
#'   (integer, how many correct moves matched) and `total_plies` (integer).
#' @export
#' @family puzzles
#' @examples
#' p <- gm_puzzle(seed = 1)
#' gm_check_solution(p, character())
gm_check_solution <- function(puzzle, moves) {
  # TODO(build): compare moves against puzzle$solution prefix.
  tibble::tibble(correct = FALSE, solved_plies = 0L,
                 total_plies = length(puzzle$solution))
}

#' @noRd
withr_local_seed <- function(seed, .local_envir = parent.frame()) {
  if (requireNamespace("withr", quietly = TRUE)) {
    withr::local_seed(seed, .local_envir = .local_envir)
  } else {
    set.seed(seed)
  }
}
