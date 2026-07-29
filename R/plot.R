#' Plot a chess board
#'
#' Render a position as a `ggplot2` object: an 8x8 board with unicode piece
#' glyphs. Returns the plot for further customisation; never draws directly.
#'
#' @param position A [gm_position] object.
#' @param highlight Optional character vector of squares to highlight (e.g.
#'   `c("e4", "d5")`).
#' @param flip If `TRUE`, view from Black's side. Default `FALSE`.
#' @return A `ggplot2` object.
#' @export
#' @family visualization
#' @examples
#' gm_plot_board(gm_position())
gm_plot_board <- function(position, highlight = NULL, flip = FALSE) {
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.")
  }
  # TODO(build): build square grid tibble, geom_tile checkerboard, geom_text glyphs.
  ggplot2::ggplot() +
    ggplot2::theme_void() +
    ggplot2::labs(title = "gm_plot_board")
}

#' Plot an evaluation curve
#'
#' Visualise how the static evaluation changes across the moves of a game.
#'
#' @param game A [gm_game] object.
#' @param depth Search depth for per-move evaluation. Default `1` (static).
#' @return A `ggplot2` object with move number on x and centipawn score on y.
#' @export
#' @family visualization
#' @examples
#' \donttest{
#' gm_plot_eval(gm_read_pgn("1. e4 e5 2. Nf3 Nc6 *", text = TRUE))
#' }
gm_plot_eval <- function(game, depth = 1L) {
  # TODO(build): evaluate each position, plot centipawn line with 0 reference.
  ggplot2::ggplot() +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "gm_plot_eval", x = "Move", y = "Evaluation (cp)")
}
