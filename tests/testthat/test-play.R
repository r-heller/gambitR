test_that("gm_simulate() returns a tidy result table", {
  res <- gm_simulate(n = 2, max_moves = 5)
  expect_s3_class(res, "tbl_df")
  expect_named(res, c("game", "result", "plies", "termination"))
})
