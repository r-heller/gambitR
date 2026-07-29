test_that("gm_plot_board() returns a ggplot object", {
  p <- gm_plot_board(gm_position())
  expect_s3_class(p, "ggplot")
})
