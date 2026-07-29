# Board and evaluation plots. Both build and return ggplot2 objects; nothing
# here draws to a device.

.GM_BOARD_LIGHT <- "#EFE6DC"
.GM_BOARD_DARK <- "#B08D6A"
.GM_ACCENT <- "#5E2C8E"

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
#'
#' # Highlight the squares of a move
#' gm_plot_board(gm_move(gm_position(), "e4"), highlight = c("e2", "e4"))
gm_plot_board <- function(position, highlight = NULL, flip = FALSE) {
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.")
  }
  if (!is.logical(flip) || length(flip) != 1L || is.na(flip)) {
    cli::cli_abort("{.arg flip} must be {.code TRUE} or {.code FALSE}.")
  }
  if (!is.null(highlight)) {
    if (!is.character(highlight)) {
      cli::cli_abort("{.arg highlight} must be a character vector of squares.")
    }
    unknown <- setdiff(highlight, .GM_SQUARES)
    if (length(unknown)) {
      cli::cli_abort(c(
        "Unknown square{?s} in {.arg highlight}: {.val {unknown}}.",
        "i" = "Squares are named {.val a1} through {.val h8}."
      ))
    }
  }
  codes <- .gm_encode_board(position$board)
  squares <- tibble::tibble(
    square = .GM_SQUARES,
    file = if (flip) 9L - .GM_COL else .GM_COL,
    rank = if (flip) .GM_ROW else 9L - .GM_ROW,
    shade = ifelse((.GM_ROW + .GM_COL) %% 2L == 0L, "light", "dark"),
    glyph = ifelse(codes == 0L, "", .GM_GLYPH[codes + 1L]),
    marked = .GM_SQUARES %in% (highlight %||% character(0L))
  )
  pieces <- squares[nzchar(squares$glyph), , drop = FALSE]
  marks <- squares[squares$marked, , drop = FALSE]

  plot <- ggplot2::ggplot(squares, ggplot2::aes(x = .data$file, y = .data$rank)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$shade), colour = NA) +
    ggplot2::scale_fill_manual(
      values = c(light = .GM_BOARD_LIGHT, dark = .GM_BOARD_DARK),
      guide = "none"
    )
  if (nrow(marks)) {
    plot <- plot + ggplot2::geom_tile(
      data = marks, fill = .GM_ACCENT, alpha = 0.35, colour = NA
    )
  }
  plot +
    ggplot2::geom_text(
      data = pieces, ggplot2::aes(label = .data$glyph),
      size = 9, colour = "grey10"
    ) +
    ggplot2::scale_x_continuous(
      breaks = 1:8, labels = if (flip) rev(letters[1:8]) else letters[1:8],
      expand = ggplot2::expansion(0)
    ) +
    ggplot2::scale_y_continuous(
      breaks = 1:8, labels = if (flip) 8:1 else 1:8,
      expand = ggplot2::expansion(0)
    ) +
    ggplot2::coord_fixed(ratio = 1) +
    ggplot2::labs(
      x = NULL, y = NULL,
      title = if (position$turn == "w") "White to move" else "Black to move",
      subtitle = gm_write_fen(position)
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(
      axis.text = ggplot2::element_text(colour = "grey40", size = 8),
      plot.title = ggplot2::element_text(face = "bold", colour = .GM_ACCENT),
      plot.subtitle = ggplot2::element_text(colour = "grey40", size = 7)
    )
}

#' Plot an evaluation curve
#'
#' Visualise how the static evaluation changes across the moves of a game.
#'
#' With `depth = 1` each position is scored by [gm_evaluate()]. A larger
#' `depth` re-scores every position with [gm_bestmove()], which is far slower
#' but accounts for tactics.
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
  if (!is_gm_game(game)) {
    cli::cli_abort("{.arg game} must be a {.cls gm_game} object.")
  }
  if (!is.numeric(depth) || length(depth) != 1L || is.na(depth) || depth < 1) {
    cli::cli_abort("{.arg depth} must be a single positive number.")
  }
  depth <- as.integer(depth)
  positions <- game$positions
  scores <- if (depth == 1L) {
    vapply(positions, gm_evaluate, numeric(1L))
  } else {
    vapply(
      positions,
      function(p) gm_bestmove(p, depth = depth, verbose = FALSE)$score,
      numeric(1L)
    )
  }
  curve <- tibble::tibble(
    ply = seq_along(scores) - 1L,
    move = (seq_along(scores) - 1L) / 2,
    score = scores,
    side = ifelse(scores >= 0, "White", "Black")
  )
  ggplot2::ggplot(curve, ggplot2::aes(x = .data$move, y = .data$score)) +
    ggplot2::geom_area(
      ggplot2::aes(fill = .data$side), alpha = 0.25, show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(values = c(White = .GM_ACCENT, Black = "grey40")) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
    ggplot2::geom_line(colour = .GM_ACCENT, linewidth = 0.7) +
    ggplot2::geom_point(colour = .GM_ACCENT, size = 1.2) +
    ggplot2::labs(
      title = "Evaluation",
      subtitle = if (depth == 1L) {
        "Static evaluation, White's perspective"
      } else {
        paste0("Search to depth ", depth, ", White's perspective")
      },
      x = "Move", y = "Evaluation (cp)"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", colour = .GM_ACCENT),
      panel.grid.minor = ggplot2::element_blank()
    )
}
