test_that("gm_position() returns a gm_position", {
  pos <- gm_position()
  expect_s3_class(pos, "gm_position")
  expect_true(is_gm_position(pos))
})

test_that("gm_read_fen() rejects non-string input", {
  expect_error(gm_read_fen(42), class = "rlang_error")
})
