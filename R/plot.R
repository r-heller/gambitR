# Board and evaluation plots. Both build and return ggplot2 objects; nothing
# here draws to a device.

.GM_BOARD_LIGHT <- "#EFE3D0"
.GM_BOARD_DARK <- "#B48762"
.GM_BOARD_FRAME <- "#6B4F38"
.GM_ACCENT <- "#5E2C8E"
.GM_CHECK <- "#B3241C"
.GM_INK <- "#332F2B"
.GM_MUTED <- "#7A736C"
.GM_PIECE_FILL <- c(white = "#FFFCF6", black = "#26221F")
.GM_PIECE_INK <- c(white = "#2B2622", black = "#F7F1E6")

# Mix two colours without relying on device alpha support: the postscript
# device has no alpha channel, so translucency has to be baked into the fill.
#' @noRd
.gm_blend <- function(top, bottom, weight) {
  a <- grDevices::col2rgb(top)
  b <- grDevices::col2rgb(bottom)
  mixed <- weight * a[, rep(1L, ncol(b)), drop = FALSE] + (1 - weight) * b
  grDevices::rgb(mixed[1L, ], mixed[2L, ], mixed[3L, ], maxColorValue = 255)
}

# One typography and spacing baseline for every plot the package draws.
#' @noRd
.gm_theme <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold", colour = .GM_ACCENT, size = ggplot2::rel(1.15),
        margin = ggplot2::margin(b = 3)
      ),
      plot.subtitle = ggplot2::element_text(
        colour = .GM_MUTED, size = ggplot2::rel(0.85),
        margin = ggplot2::margin(b = 8)
      ),
      plot.caption = ggplot2::element_text(
        colour = .GM_MUTED, size = ggplot2::rel(0.7), hjust = 0,
        margin = ggplot2::margin(t = 8)
      ),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      axis.title = ggplot2::element_text(colour = .GM_MUTED, size = ggplot2::rel(0.85)),
      axis.text = ggplot2::element_text(colour = .GM_MUTED, size = ggplot2::rel(0.8)),
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour = .GM_INK, size = ggplot2::rel(0.8)),
      legend.key.size = ggplot2::unit(9, "pt"),
      legend.position = "top",
      legend.justification = "left",
      legend.margin = ggplot2::margin(b = 2),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "#E8E4DF", linewidth = 0.3),
      plot.margin = ggplot2::margin(10, 12, 8, 10)
    )
}

# Material balance in pawns from White's point of view, on the conventional
# 1/3/3/5/9 scale rather than the engine's centipawn weights, so that a
# bishop-for-knight trade reads as level.
.GM_MATERIAL_UNIT <- c(1, 3, 3, 5, 9, 0)

#' @noRd
.gm_material <- function(codes) {
  on <- codes[codes > 0L]
  if (!length(on)) {
    return(0)
  }
  ptype <- ((on - 1L) %% 6L) + 1L
  sum(ifelse(on <= 6L, 1, -1) * .GM_MATERIAL_UNIT[ptype])
}

# Plot text has to survive the pdf and postscript devices, which encode to a
# single-byte charset: an em dash there raises "substituted for <U+2014>". The
# separators below are either plain ASCII or, like the middle dot, part of
# Latin-1. They are written as escapes so the source file stays ASCII.
#' @noRd
.gm_board_title <- function(position) {
  status <- gm_status(position)
  mover <- if (identical(position$turn, "w")) "White" else "Black"
  waiter <- if (identical(position$turn, "w")) "Black" else "White"
  switch(status,
    checkmate = paste0("Checkmate: ", waiter, " wins"),
    stalemate = "Stalemate: draw",
    check = paste0(mover, " to move, in check"),
    paste0(mover, " to move")
  )
}

#' Plot a chess board
#'
#' Render a position as a `ggplot2` object: an 8x8 board with the pieces drawn
#' as vector shapes. Returns the plot for further customisation; never draws
#' directly. Drop the annotations with
#' `gm_plot_board(p) + ggplot2::labs(title = NULL, subtitle = NULL)`, or add the
#' `FEN` yourself with
#' `gm_plot_board(p) + ggplot2::labs(caption = gm_write_fen(p))`.
#'
#' The pieces are polygons rather than text, so they scale with the square and
#' stay legible from a 2-inch figure to a full page, and the board renders on
#' every graphics device including pdf and postscript.
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
  side <- ifelse(codes == 0L, NA_character_, ifelse(codes <= 6L, "white", "black"))
  squares <- tibble::tibble(
    square = .GM_SQUARES,
    file = if (flip) 9L - .GM_COL else .GM_COL,
    rank = if (flip) .GM_ROW else 9L - .GM_ROW,
    shade = ifelse((.GM_ROW + .GM_COL) %% 2L == 0L, "light", "dark"),
    piece = ifelse(codes == 0L, "", .GM_PIECE_LETTER[((codes - 1L) %% 6L) + 1L]),
    side = side,
    fill = ifelse(
      (.GM_ROW + .GM_COL) %% 2L == 0L, .GM_BOARD_LIGHT, .GM_BOARD_DARK
    ),
    marked = .GM_SQUARES %in% (highlight %||% character(0L))
  )
  pieces <- squares[nzchar(squares$piece), , drop = FALSE]
  if (nrow(pieces)) {
    pieces$fill <- unname(.GM_PIECE_FILL[pieces$side])
    pieces$ink <- unname(.GM_PIECE_INK[pieces$side])
  }
  marks <- squares[squares$marked, , drop = FALSE]

  # The king in check gets its own tint so the reader sees the threat without
  # having to work the position out.
  checked <- character(0L)
  if (identical(gm_status(position), "check") ||
    identical(gm_status(position), "checkmate")) {
    king <- if (identical(position$turn, "w")) 6L else 12L
    checked <- .GM_SQUARES[codes == king]
  }
  alarm <- squares[squares$square %in% checked, , drop = FALSE]

  plot <- ggplot2::ggplot(squares, ggplot2::aes(x = .data$file, y = .data$rank)) +
    ggplot2::geom_tile(
      ggplot2::aes(fill = .data$fill),
      width = 1, height = 1, colour = NA
    ) +
    ggplot2::scale_fill_identity(guide = "none")
  # Blend the tints into the square rather than layering translucent tiles:
  # the postscript device has no alpha channel. Blending also preserves the
  # checkerboard underneath the tint.
  # A light tint plus a firm outline: the tint stays close in value on both
  # square shades, and the outline carries the signal.
  if (nrow(alarm)) {
    alarm$fill <- .gm_blend(.GM_CHECK, alarm$fill, 0.34)
    plot <- plot +
      ggplot2::geom_tile(
        data = alarm, ggplot2::aes(fill = .data$fill),
        width = 1, height = 1, colour = NA
      ) +
      ggplot2::geom_tile(
        data = alarm, fill = NA, colour = .GM_CHECK,
        width = 0.92, height = 0.92, linewidth = 0.8
      )
  }
  if (nrow(marks)) {
    marks$fill <- .gm_blend(.GM_ACCENT, marks$fill, 0.28)
    plot <- plot +
      ggplot2::geom_tile(
        data = marks, ggplot2::aes(fill = .data$fill),
        width = 1, height = 1, colour = NA
      ) +
      ggplot2::geom_tile(
        data = marks, fill = NA, colour = .GM_ACCENT,
        width = 0.92, height = 0.92, linewidth = 0.8
      )
  }
  if (nrow(pieces)) {
    body <- .gm_piece_polygons(pieces, "body")
    detail <- .gm_piece_polygons(pieces, "detail")
    plot <- plot +
      ggplot2::geom_polygon(
        data = body,
        ggplot2::aes(
          x = .data$x, y = .data$y, group = .data$group,
          fill = .data$fill, colour = .data$ink
        ),
        linewidth = 0.35
      ) +
      ggplot2::geom_polygon(
        data = detail,
        ggplot2::aes(x = .data$x, y = .data$y, group = .data$group, fill = .data$fill),
        colour = NA
      ) +
      ggplot2::scale_colour_identity(guide = "none")
  }

  balance <- .gm_material(codes)
  subtitle <- paste0(
    "Move ", position$fullmove, "  \u00b7  ",
    if (balance > 0) {
      paste0("White +", balance)
    } else if (balance < 0) {
      paste0("Black +", -balance)
    } else {
      "material level"
    }
  )

  plot +
    ggplot2::annotate(
      "rect",
      xmin = 0.5, xmax = 8.5, ymin = 0.5, ymax = 8.5,
      fill = NA, colour = .GM_BOARD_FRAME, linewidth = 0.9
    ) +
    ggplot2::scale_x_continuous(
      breaks = 1:8, labels = if (flip) rev(letters[1:8]) else letters[1:8],
      expand = ggplot2::expansion(add = 0.06), position = "bottom"
    ) +
    ggplot2::scale_y_continuous(
      breaks = 1:8, labels = if (flip) 8:1 else 1:8,
      expand = ggplot2::expansion(add = 0.06)
    ) +
    ggplot2::coord_fixed(ratio = 1, clip = "off") +
    ggplot2::labs(
      x = NULL, y = NULL,
      title = .gm_board_title(position),
      subtitle = subtitle
    ) +
    .gm_theme() +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(
        colour = .GM_MUTED, size = ggplot2::rel(0.75), face = "bold"
      ),
      axis.text.x = ggplot2::element_text(margin = ggplot2::margin(t = 3)),
      axis.text.y = ggplot2::element_text(margin = ggplot2::margin(r = 4)),
      axis.ticks = ggplot2::element_blank()
    )
}

# Insert interpolated zero crossings so a ribbon drawn from the axis to the
# score meets the axis exactly where the advantage changes hands. Without
# this the fill spills across the sign change.
#' @noRd
.gm_split_at_zero <- function(x, y) {
  if (length(x) < 2L) {
    return(list(x = x, y = y))
  }
  out_x <- numeric(0)
  out_y <- numeric(0)
  for (i in seq_along(x)) {
    out_x <- c(out_x, x[[i]])
    out_y <- c(out_y, y[[i]])
    if (i < length(x) && sign(y[[i]]) * sign(y[[i + 1L]]) < 0) {
      t <- y[[i]] / (y[[i]] - y[[i + 1L]])
      out_x <- c(out_x, x[[i]] + t * (x[[i + 1L]] - x[[i]]))
      out_y <- c(out_y, 0)
    }
  }
  list(x = out_x, y = out_y)
}

#' Plot an evaluation curve
#'
#' Visualise how the evaluation changes across the moves of a game. The area
#' between the curve and the axis is filled towards whichever side is ahead,
#' split exactly at the ply where the advantage changes hands.
#'
#' With `depth = 1` each position is scored by [gm_evaluate()]. A larger
#' `depth` re-scores every position with [gm_bestmove()], which is far slower
#' but accounts for tactics. Forced mates are clamped for display so a single
#' mate score cannot flatten the rest of the curve.
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
  if (!is.numeric(depth) || length(depth) != 1L || !is.finite(depth) || depth < 1 ||
      depth != trunc(depth) || depth > .Machine$integer.max) {
    cli::cli_abort("{.arg depth} must be a single positive whole number.")
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
  # A mate score is 100000; left alone it would flatten everything else.
  capped <- any(abs(scores) > 1500)
  scores <- pmax(pmin(scores, 1500), -1500)
  curve <- tibble::tibble(
    ply = seq_along(scores) - 1L,
    move = (seq_along(scores) - 1L) / 2,
    score = scores,
    side = ifelse(scores >= 0, "White", "Black")
  )
  split <- .gm_split_at_zero(curve$ply, curve$score)
  band <- tibble::tibble(
    ply = split$x,
    score = split$y,
    top = pmax(split$y, 0),
    bottom = pmin(split$y, 0)
  )
  span <- max(curve$ply)
  step <- if (span <= 12) 2L else if (span <= 40) 4L else 2L * ceiling(span / 20)
  breaks <- seq(0L, span, by = max(step, 2L))
  # A symmetric axis keeps "level" in the middle of the panel, so the two
  # ribbons are directly comparable, and it stops a flat game from being drawn
  # against a fractional axis: centipawns are whole numbers.
  reach <- max(50, max(abs(curve$score)))
  # Only name the sides that actually take the lead.
  ahead <- c(
    if (any(curve$score > 0)) "White ahead",
    if (any(curve$score < 0)) "Black ahead"
  )

  ggplot2::ggplot(curve, ggplot2::aes(x = .data$ply, y = .data$score)) +
    ggplot2::geom_ribbon(
      data = band,
      ggplot2::aes(x = .data$ply, ymin = 0, ymax = .data$top, fill = "White ahead"),
      inherit.aes = FALSE
    ) +
    ggplot2::geom_ribbon(
      data = band,
      ggplot2::aes(x = .data$ply, ymin = .data$bottom, ymax = 0, fill = "Black ahead"),
      inherit.aes = FALSE
    ) +
    ggplot2::scale_fill_manual(
      values = c("White ahead" = "#C9B6DF", "Black ahead" = "#BFC6CE"),
      breaks = if (length(ahead)) ahead else NULL
    ) +
    ggplot2::geom_hline(yintercept = 0, colour = .GM_BOARD_FRAME, linewidth = 0.4) +
    ggplot2::geom_line(colour = .GM_ACCENT, linewidth = 0.7) +
    ggplot2::geom_point(colour = .GM_ACCENT, fill = "white", shape = 21, size = 1.5, stroke = 0.6) +
    ggplot2::scale_x_continuous(
      breaks = breaks, labels = breaks %/% 2L,
      expand = ggplot2::expansion(mult = c(0.01, 0.03))
    ) +
    ggplot2::scale_y_continuous(
      limits = c(-reach, reach),
      breaks = function(limits) unique(round(pretty(limits, n = 5L))),
      labels = function(v) ifelse(v > 0, paste0("+", v), as.character(v)),
      expand = ggplot2::expansion(mult = 0.04)
    ) +
    ggplot2::labs(
      title = "Evaluation",
      subtitle = paste0(
        if (depth == 1L) "Static score" else paste0("Search to depth ", depth),
        ", centipawns from White's point of view",
        if (capped) "; forced mates clamped to \u00b11500" else ""
      ),
      x = "Move", y = NULL
    ) +
    .gm_theme() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank())
}
