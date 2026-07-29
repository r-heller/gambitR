# Vector geometry for the six chess pieces.
#
# The board renderer draws pieces as filled polygons rather than as text.
# That is what makes them legible: a polygon is defined in *board units*, so a
# piece is always exactly as large as its square whatever the output size,
# and it is recognisable by silhouette instead of by a letter. It also
# sidesteps fonts entirely, which matters because the U+2654-U+265F chess
# glyphs cannot be encoded on the pdf and postscript devices.
#
# Each piece is a list with two slots:
#
#   body    closed paths filled in the piece colour and stroked in the ink
#           colour (the silhouette and any separate finials).
#   detail  closed paths filled in the ink colour with no stroke (collars,
#           the bishop's slit, the knight's eye and mane).
#
# Coordinates are centred on (0, 0) and stay inside about
# x = [-0.34, 0.34], y = [-0.36, 0.43] so that pieces on neighbouring squares
# never collide.

#' @noRd
.gm_arc <- function(cx, cy, r, from, to, n = 20L) {
  theta <- seq(from, to, length.out = n) * pi / 180
  list(x = cx + r * cos(theta), y = cy + r * sin(theta))
}

#' @noRd
.gm_disc <- function(cx, cy, r, n = 22L) {
  theta <- seq(0, 2 * pi, length.out = n + 1L)[-(n + 1L)]
  list(x = cx + r * cos(theta), y = cy + r * sin(theta))
}

# Close a right-hand profile into a full outline by reflecting it about x = 0.
#' @noRd
.gm_sym <- function(x, y) {
  list(x = c(x, rev(-x)), y = c(y, rev(y)))
}

#' @noRd
.gm_path <- function(x, y) list(x = x, y = y)

.GM_PIECE_SHAPES <- local({
  # A trapezoidal plinth shared by every piece, expressed as the first four
  # points of the right-hand profile.
  pawn <- list(
    body = list(
      .gm_sym(
        x = c(0.235, 0.235, 0.165, 0.128, 0.150, 0.150, 0.092, 0.086),
        y = c(-0.355, -0.298, -0.252, -0.186, -0.160, -0.126, -0.082, 0.020)
      ),
      .gm_disc(0, 0.128, 0.140)
    ),
    detail = list(
      .gm_path(
        x = c(-0.150, 0.150, 0.150, -0.150),
        y = c(-0.160, -0.160, -0.126, -0.126)
      )
    )
  )

  rook <- list(
    body = list(
      .gm_sym(
        x = c(
          0.300, 0.300, 0.238, 0.190, 0.152, 0.142, 0.186, 0.248,
          0.290, 0.290, 0.186, 0.186, 0.130, 0.130, 0.046, 0.046, 0.000
        ),
        y = c(
          -0.355, -0.296, -0.252, -0.212, -0.128, 0.020, 0.060, 0.096,
          0.136, 0.300, 0.300, 0.206, 0.206, 0.300, 0.300, 0.206, 0.206
        )
      )
    ),
    detail = list(
      .gm_path(
        x = c(-0.186, 0.186, 0.248, -0.248),
        y = c(0.060, 0.060, 0.096, 0.096)
      ),
      .gm_path(
        x = c(-0.190, 0.190, 0.238, -0.238),
        y = c(-0.212, -0.212, -0.252, -0.252)
      )
    )
  )

  bishop <- list(
    body = list(
      .gm_sym(
        x = c(
          0.285, 0.285, 0.216, 0.166, 0.136, 0.196, 0.206,
          0.146, 0.116, 0.121, 0.100, 0.062, 0.000
        ),
        y = c(
          -0.355, -0.296, -0.252, -0.208, -0.148, -0.114, -0.074,
          -0.038, 0.022, 0.090, 0.146, 0.216, 0.282
        )
      ),
      .gm_disc(0, 0.308, 0.048)
    ),
    detail = list(
      .gm_path(
        x = c(-0.146, 0.146, 0.206, -0.206),
        y = c(-0.038, -0.038, -0.074, -0.074)
      ),
      .gm_path(
        x = c(-0.050, 0.070, 0.104, -0.016),
        y = c(0.186, 0.042, 0.072, 0.216)
      )
    )
  )

  knight <- list(
    body = list(
      .gm_path(
        x = c(
          0.300, 0.300, 0.236, 0.206, 0.200, 0.216, 0.196, 0.142,
          0.082, 0.046, 0.012, -0.046, -0.120, -0.206, -0.276, -0.316,
          -0.320, -0.266, -0.230, -0.180, -0.135, -0.150, -0.216,
          -0.300, -0.300
        ),
        y = c(
          -0.355, -0.296, -0.252, -0.180, -0.060, 0.058, 0.168, 0.264,
          0.318, 0.284, 0.392, 0.290, 0.264, 0.214, 0.130, 0.046,
          -0.010, -0.030, -0.014, -0.056, -0.126, -0.216, -0.264,
          -0.296, -0.355
        )
      )
    ),
    detail = list(
      .gm_path(
        x = c(0.216, 0.196, 0.142, 0.082, 0.046, 0.062, 0.108, 0.146, 0.158),
        y = c(0.054, 0.164, 0.260, 0.314, 0.282, 0.238, 0.190, 0.118, 0.038)
      ),
      .gm_disc(-0.136, 0.182, 0.031, 14L),
      .gm_path(
        x = c(-0.302, -0.248, -0.240, -0.294),
        y = c(0.010, -0.008, 0.014, 0.032)
      )
    )
  )

  queen <- list(
    body = list(
      .gm_sym(
        x = c(
          0.308, 0.308, 0.240, 0.186, 0.150, 0.130, 0.186,
          0.214, 0.230, 0.308, 0.328, 0.234, 0.170, 0.080, 0.000
        ),
        y = c(
          -0.355, -0.296, -0.252, -0.208, -0.138, -0.028, 0.020,
          0.066, 0.110, 0.184, 0.286, 0.178, 0.312, 0.174, 0.346
        )
      ),
      .gm_disc(0.328, 0.298, 0.049),
      .gm_disc(-0.328, 0.298, 0.049),
      .gm_disc(0.170, 0.324, 0.049),
      .gm_disc(-0.170, 0.324, 0.049),
      .gm_disc(0, 0.358, 0.053)
    ),
    detail = list(
      .gm_path(
        x = c(-0.190, 0.190, 0.222, -0.222),
        y = c(0.026, 0.026, 0.082, 0.082)
      ),
      .gm_path(
        x = c(-0.190, 0.190, 0.238, -0.238),
        y = c(-0.208, -0.208, -0.252, -0.252)
      )
    )
  )

  king <- list(
    body = list(
      .gm_sym(
        x = c(
          0.308, 0.308, 0.240, 0.186, 0.150, 0.130, 0.190,
          0.226, 0.256, 0.236, 0.150, 0.076, 0.055
        ),
        y = c(
          -0.355, -0.296, -0.252, -0.208, -0.138, -0.028, 0.016,
          0.070, 0.146, 0.216, 0.186, 0.234, 0.248
        )
      ),
      .gm_path(
        x = c(
          -0.040, 0.040, 0.040, 0.115, 0.115, 0.040,
          0.040, -0.040, -0.040, -0.115, -0.115, -0.040
        ),
        y = c(
          0.238, 0.238, 0.300, 0.300, 0.364, 0.364,
          0.424, 0.424, 0.364, 0.364, 0.300, 0.300
        )
      )
    ),
    detail = list(
      .gm_path(
        x = c(-0.190, 0.190, 0.226, -0.226),
        y = c(0.016, 0.016, 0.070, 0.070)
      ),
      .gm_path(
        x = c(-0.190, 0.190, 0.238, -0.238),
        y = c(-0.208, -0.208, -0.252, -0.252)
      )
    )
  )

  list(P = pawn, N = knight, B = bishop, R = rook, Q = queen, K = king)
})

# How much of the square a piece takes up. Large enough to have presence,
# small enough that pieces on neighbouring squares never touch.
.GM_PIECE_SCALE <- 1.09

# Assemble the polygon data for one board: `pieces` carries one row per
# occupied square with its centre, colours and piece letter.
#' @noRd
.gm_piece_polygons <- function(pieces, which) {
  if (!nrow(pieces)) {
    return(NULL)
  }
  parts <- vector("list", nrow(pieces) * 6L)
  k <- 0L
  for (i in seq_len(nrow(pieces))) {
    shape <- .GM_PIECE_SHAPES[[pieces$piece[[i]]]][[which]]
    for (j in seq_along(shape)) {
      k <- k + 1L
      parts[[k]] <- data.frame(
        x = pieces$file[[i]] + shape[[j]]$x * .GM_PIECE_SCALE,
        y = pieces$rank[[i]] + shape[[j]]$y * .GM_PIECE_SCALE,
        group = paste0(pieces$square[[i]], ".", which, j),
        fill = if (identical(which, "body")) pieces$fill[[i]] else pieces$ink[[i]],
        ink = pieces$ink[[i]],
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, parts[seq_len(k)])
}
