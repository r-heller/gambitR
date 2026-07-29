test_that("gm_plot_board() returns a ggplot object", {
  p <- gm_plot_board(gm_position())
  expect_s3_class(p, "ggplot")
})

test_that("the board plot has the expected layers", {
  plain <- gm_plot_board(gm_position())
  expect_length(plain$layers, 3L)
  expect_s3_class(plain$layers[[1L]]$geom, "GeomTile")
  expect_s3_class(plain$layers[[2L]]$geom, "GeomPoint")
  expect_s3_class(plain$layers[[3L]]$geom, "GeomText")
  expect_equal(nrow(plain$layers[[3L]]$data), 32L)

  marked <- gm_plot_board(gm_position(), highlight = c("e2", "e4"))
  expect_length(marked$layers, 4L)
  expect_s3_class(marked$layers[[2L]]$geom, "GeomTile")
  expect_equal(nrow(marked$layers[[2L]]$data), 2L)

  bare <- gm_plot_board(gm_position("8/8/4k3/8/8/4K3/8/8 w - - 0 1"))
  expect_length(bare$layers, 3L)
})

test_that("the board renders on the pdf and postscript devices", {
  # The U+2654-U+265F glyphs cannot be encoded there, which is why the plot
  # uses lettered discs.
  for (open in list(
    function(f) grDevices::pdf(f),
    function(f) grDevices::postscript(f)
  )) {
    path <- withr::local_tempfile()
    open(path)
    expect_silent(print(gm_plot_board(gm_position(), highlight = "e4")))
    grDevices::dev.off()
  }
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
  expect_equal(
    length(ggplot2::autoplot(gm_position(), highlight = "e4")$layers), 4L
  )
})

test_that("gm_plot_eval() returns a ggplot with one point per position", {
  game <- gm_read_pgn("1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 *", text = TRUE)
  p <- gm_plot_eval(game)
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), length(game$positions))
  expect_named(p$data, c("ply", "move", "score", "side"))
  expect_equal(p$labels$y, "Evaluation (cp)")
  expect_equal(p$labels$x, "Move")
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
    "positive number"
  )
})
