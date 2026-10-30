test_that("gm_plot_board() returns a ggplot object", {
  p <- gm_plot_board(gm_position())
  expect_s3_class(p, "ggplot")
})

geom_names <- function(plot) {
  unname(vapply(plot$layers, function(layer) class(layer$geom)[[1L]], character(1L)))
}

tile_layers <- function(plot) {
  Filter(function(layer) inherits(layer$geom, "GeomTile"), plot$layers)
}

test_that("the board plot has the expected layers", {
  # Squares, then the piece silhouettes, then the detail paths, then the frame.
  plain <- gm_plot_board(gm_position())
  expect_identical(
    geom_names(plain),
    c("GeomTile", "GeomPolygon", "GeomPolygon", "GeomRect")
  )

  # Exactly the occupied squares carry a piece, and each contributes at least
  # one closed path. The group name is "<square>.<part><n>".
  body <- plain$layers[[2L]]$data
  expect_setequal(
    unique(sub("\\..*$", "", body$group)),
    plain$data$square[nzchar(plain$data$piece)]
  )

  # A highlight adds a tinted tile and its outline, and nothing else.
  marked <- gm_plot_board(gm_position(), highlight = c("e2", "e4"))
  expect_identical(
    geom_names(marked),
    c("GeomTile", "GeomTile", "GeomTile", "GeomPolygon", "GeomPolygon", "GeomRect")
  )
  for (layer in tile_layers(marked)[-1L]) {
    expect_setequal(layer$data$square, c("e2", "e4"))
  }

  # An empty board still draws the two kings and the frame.
  bare <- gm_plot_board(gm_position("8/8/4k3/8/8/4K3/8/8 w - - 0 1"))
  expect_identical(
    geom_names(bare),
    c("GeomTile", "GeomPolygon", "GeomPolygon", "GeomRect")
  )
  expect_setequal(
    unique(sub("\\..*$", "", bare$layers[[2L]]$data$group)), c("e3", "e6")
  )
})

test_that("a highlighted tile is one square, not the span of the selection", {
  # geom_tile infers width and height from the resolution of the data it is
  # given, so highlighting two squares two ranks apart used to paint a
  # two-rank block.
  marked <- gm_plot_board(gm_position(), highlight = c("e7", "e5"))
  tint <- tile_layers(marked)[[2L]]
  expect_equal(tint$aes_params$width, 1)
  expect_equal(tint$aes_params$height, 1)
})

test_that("highlights blend into the square instead of using alpha", {
  # The postscript device has no alpha channel, so the tint has to be baked
  # into the fill. A blend also leaves the checkerboard readable, which shows
  # up as a different fill on the light and the dark square.
  marked <- gm_plot_board(gm_position(), highlight = c("d4", "e4"))
  tint <- tile_layers(marked)[[2L]]
  expect_null(tint$aes_params$alpha)
  expect_length(unique(tint$data$fill), 2L)
  expect_false(any(tint$data$fill == .GM_ACCENT))
  expect_false(any(tint$data$fill %in% c(.GM_BOARD_LIGHT, .GM_BOARD_DARK)))
})

test_that("the king in check is marked and named in the title", {
  mate <- gm_plot_board(
    gm_position("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")
  )
  alarm <- tile_layers(mate)[[2L]]
  expect_identical(alarm$data$square, "e1")
  expect_false(alarm$data$fill == .GM_BOARD_DARK)
  expect_match(mate$labels$title, "Checkmate")
})

test_that("the board never draws a piece as text or as a chess glyph", {
  # The U+2654-U+265F glyphs cannot be encoded on the pdf and postscript
  # devices, so the pieces are polygons and no layer may fall back to text.
  boards <- list(
    gm_plot_board(gm_position()),
    gm_plot_board(gm_position(), highlight = "e4"),
    gm_plot_board(gm_position("8/8/4k3/8/8/4K3/8/8 w - - 0 1"))
  )
  for (board in boards) {
    expect_false(any(geom_names(board) %in% c("GeomText", "GeomLabel")))
    drawn <- unlist(lapply(board$layers, function(layer) {
      if (is.data.frame(layer$data)) unlist(lapply(layer$data, as.character))
    }))
    expect_false(any(drawn %in% .GM_GLYPH[-1L]))
  }
})

test_that("the board renders on the pdf and postscript devices", {
  for (open in list(
    function(f) grDevices::pdf(f),
    function(f) grDevices::postscript(f)
  )) {
    path <- withr::local_tempfile()
    open(path)
    expect_silent(print(gm_plot_board(gm_position(), highlight = "e4")))
    expect_silent(print(gm_plot_board(
      gm_position("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")
    )))
    grDevices::dev.off()
  }
})

test_that("the board subtitle reports the move number and the material", {
  expect_match(gm_plot_board(gm_position())$labels$subtitle, "Move 1")
  expect_match(gm_plot_board(gm_position())$labels$subtitle, "material level")
  expect_match(
    gm_plot_board(gm_position("8/8/4k3/8/2P5/4K3/8/8 w - - 0 42"))$labels$subtitle,
    "White \\+1"
  )
  expect_match(
    gm_plot_board(gm_position("3qk3/8/8/8/8/8/8/4K3 w - - 0 1"))$labels$subtitle,
    "Black \\+9"
  )
  # The raw FEN is machine data: it has no whitespace to wrap on and so it
  # cannot be laid out across figure widths. It stays out of the plot.
  expect_null(gm_plot_board(gm_position())$labels$caption)
})

test_that("the board grid is a full 64-square checkerboard", {
  data <- gm_plot_board(gm_position())$data
  expect_equal(nrow(data), 64L)
  expect_setequal(data$square, .GM_SQUARES)
  expect_equal(sum(data$shade == "dark"), 32L)
  expect_identical(data$shade[data$square == "a1"], "dark")
  expect_identical(data$shade[data$square == "h1"], "light")
  expect_equal(sum(nzchar(data$piece)), 32L)
  expect_identical(data$piece[data$square == "e1"], "K")
  expect_identical(data$side[data$square == "e1"], "white")
  expect_identical(data$side[data$square == "e8"], "black")
  expect_true(is.na(data$side[data$square == "e4"]))
})

test_that("flipping mirrors the board", {
  normal <- gm_plot_board(gm_position())$data
  flipped <- gm_plot_board(gm_position(), flip = TRUE)$data
  expect_equal(
    normal$file[normal$square == "a1"], 9L - flipped$file[flipped$square == "a1"]
  )
  expect_equal(
    normal$rank[normal$square == "a1"], 9L - flipped$rank[flipped$square == "a1"]
  )
})

test_that("the board plot renders without warnings", {
  skip_on_cran()
  path <- withr::local_tempfile(fileext = ".png")
  expect_silent(suppressMessages(ggplot2::ggsave(
    path, gm_plot_board(gm_move(gm_position(), "e4"), highlight = "e4"),
    width = 4, height = 4, dpi = 72
  )))
  expect_true(file.exists(path))
})

test_that("gm_plot_board() validates its arguments", {
  expect_error(gm_plot_board("start"), class = "rlang_error")
  expect_error(gm_plot_board(gm_position(), highlight = "z9"), "Unknown square")
  expect_error(gm_plot_board(gm_position(), highlight = 1), "character vector")
  expect_error(gm_plot_board(gm_position(), flip = "yes"), "TRUE")
})

test_that("autoplot() dispatches to gm_plot_board()", {
  via_autoplot <- ggplot2::autoplot(gm_position())
  expect_s3_class(via_autoplot, "ggplot")
  expect_equal(nrow(via_autoplot$data), 64L)
  expect_identical(
    geom_names(ggplot2::autoplot(gm_position(), highlight = "e4")),
    geom_names(gm_plot_board(gm_position(), highlight = "e4"))
  )
})

test_that("gm_plot_eval() returns a ggplot with one point per position", {
  game <- gm_read_pgn("1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 *", text = TRUE)
  p <- gm_plot_eval(game)
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), length(game$positions))
  expect_named(p$data, c("ply", "move", "score", "side"))
  expect_equal(p$labels$x, "Move")
  # The y axis carries bare numbers, so the unit has to be stated somewhere.
  expect_match(p$labels$subtitle, "centipawns")
  expect_match(p$labels$subtitle, "White")
})

test_that("gm_plot_eval() labels whole moves on x and whole centipawns on y", {
  game <- gm_read_pgn("1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 *", text = TRUE)
  built <- ggplot2::ggplot_build(gm_plot_eval(game))
  x <- built$layout$panel_params[[1L]]
  expect_true(all(x$x$get_labels() == as.character(as.integer(x$x$get_labels()))))
  labels <- sub("^\\+", "", x$y$get_labels())
  labels <- labels[!is.na(labels)]
  expect_true(all(labels == as.character(as.integer(labels))))

  # A game with no advantage either way must not fall back to a fractional
  # axis, and neither ribbon should be named in the legend.
  flat <- gm_plot_eval(gm_read_pgn("*", text = TRUE))
  flat_y <- ggplot2::ggplot_build(flat)$layout$panel_params[[1L]]$y
  expect_true(all(abs(flat_y$get_limits()) >= 50))
  labels <- sub("^\\+", "", flat_y$get_labels())
  labels <- labels[!is.na(labels)]
  expect_true(all(labels == as.character(as.integer(labels))))
})

test_that("gm_plot_eval() can search instead of scoring statically", {
  skip_on_cran()
  game <- gm_read_pgn("1. e4 e5 *", text = TRUE)
  deep <- gm_plot_eval(game, depth = 2L)
  expect_s3_class(deep, "ggplot")
  expect_equal(nrow(deep$data), 3L)
})

test_that("gm_plot_eval() handles an empty game", {
  game <- gm_read_pgn("*", text = TRUE)
  expect_s3_class(gm_plot_eval(game), "ggplot")
})

test_that("gm_plot_eval() validates its arguments", {
  expect_error(gm_plot_eval(gm_position()), class = "rlang_error")
  expect_error(
    gm_plot_eval(gm_read_pgn("1. e4 *", text = TRUE), depth = 0),
    "positive whole number"
  )
})
