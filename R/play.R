#' Play a full game between two strategies
#'
#' Run a self-play game from a starting position until termination, with each
#' side driven by a strategy function.
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
#' gm_play(white = "random", black = "random", max_moves = 10)
#' }
gm_play <- function(white = "engine", black = "engine", position = NULL,
                    max_moves = 200L, verbose = TRUE) {
  position <- position %||% gm_position()
  # TODO(build): main game loop, resolve strategy shortcuts, detect termination.
  new_gm_game()
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
#' gm_simulate(white = "random", black = "random", n = 3, max_moves = 20)
#' }
gm_simulate <- function(white = "random", black = "random", n = 10L,
                        max_moves = 200L, verbose = TRUE) {
  # TODO(build): loop gm_play n times with cli progress bar; aggregate results.
  tibble::tibble(
    game = integer(), result = character(),
    plies = integer(), termination = character()
  )
}
