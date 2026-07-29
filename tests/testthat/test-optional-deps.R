# The package must load and work with none of the Suggests installed. These
# tests simulate that by making every requireNamespace() call fail.

test_that("gm_run_app() explains which package is missing", {
  local_mocked_bindings(requireNamespace = function(...) FALSE, .package = "base")
  expect_error(gm_run_app(), "shiny")
})

test_that("gm_uci_bestmove() explains that processx is missing", {
  local_mocked_bindings(requireNamespace = function(...) FALSE, .package = "base")
  expect_error(gm_uci_bestmove(gm_position()), "processx")
  expect_false(.gm_has_uci())
})

test_that("gm_puzzle() falls back to set.seed() without withr", {
  local_mocked_bindings(requireNamespace = function(...) FALSE, .package = "base")
  first <- gm_puzzle(seed = 7)
  second <- gm_puzzle(seed = 7)
  expect_identical(first$id, second$id)
  expect_s3_class(first, "gm_puzzle")
})

test_that("the core of the package needs no optional package at all", {
  local_mocked_bindings(requireNamespace = function(...) FALSE, .package = "base")
  pos <- gm_move(gm_position(), "e4")
  expect_s3_class(pos, "gm_position")
  expect_gt(nrow(gm_legal_moves(pos)), 0L)
  expect_type(gm_evaluate(pos), "double")
  expect_s3_class(gm_bestmove(pos, depth = 1L, verbose = FALSE), "tbl_df")
  expect_s3_class(gm_plot_board(pos), "ggplot")
  expect_gt(nrow(gm_openings("Sicilian")), 0L)
  expect_s3_class(gm_read_pgn("1. e4 e5 *", text = TRUE), "gm_game")
})
