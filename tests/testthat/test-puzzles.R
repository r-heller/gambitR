test_that("gm_puzzle() returns a gm_puzzle", {
  p <- gm_puzzle(seed = 1)
  expect_s3_class(p, "gm_puzzle")
  expect_s3_class(p$position, "gm_position")
  expect_type(p$solution, "character")
  expect_type(p$theme, "character")
  expect_type(p$rating, "integer")
  expect_gt(length(p$solution), 0L)
})

test_that("gm_puzzle() is reproducible under a seed", {
  expect_identical(gm_puzzle(seed = 42)$id, gm_puzzle(seed = 42)$id)
})

test_that("gm_puzzle() selects by id and theme", {
  expect_identical(gm_puzzle(id = "gm-0001")$id, "gm-0001")
  expect_identical(gm_puzzle(id = "gm-0001")$solution, "Ra8#")
  expect_identical(gm_puzzle(theme = "mateIn2", seed = 1)$theme, "mateIn2")
  expect_error(gm_puzzle(id = "nope"), "No puzzle with id")
  expect_error(gm_puzzle(theme = "zugzwang"), "No puzzle with theme")
  expect_error(gm_puzzle(id = 1), "single non-NA string")
  expect_error(gm_puzzle(theme = 1), "single non-NA string")
})

test_that("every bundled puzzle solution is legal and sound", {
  set <- .gm_puzzle_set()
  expect_gt(nrow(set), 0L)
  for (i in seq_len(nrow(set))) {
    p <- gm_puzzle(id = set$id[[i]])
    position <- p$position
    for (san in p$solution) {
      expect_true(san %in% gm_legal_moves(position)$san)
      position <- gm_move(position, san)
    }
    last <- p$solution[[length(p$solution)]]
    if (grepl("#$", last)) {
      expect_identical(gm_status(position), "checkmate")
    }
  }
})

test_that("a puzzle's own solution checks as correct", {
  set <- .gm_puzzle_set()
  for (i in seq_len(nrow(set))) {
    p <- gm_puzzle(id = set$id[[i]])
    res <- gm_check_solution(p, p$solution)
    expect_true(res$correct)
    expect_equal(res$solved_plies, length(p$solution))
    expect_equal(res$total_plies, length(p$solution))
  }
})

test_that("gm_check_solution() returns the declared one-row tibble", {
  p <- gm_puzzle(id = "gm-0001")
  res <- gm_check_solution(p, character())
  expect_s3_class(res, "tbl_df")
  expect_named(res, c("correct", "solved_plies", "total_plies"))
  expect_equal(nrow(res), 1L)
  expect_false(res$correct)
  expect_equal(res$solved_plies, 0L)
  expect_type(res$total_plies, "integer")
})

test_that("gm_check_solution() scores partial and wrong attempts", {
  p <- gm_puzzle(id = "gm-0008")
  expect_equal(length(p$solution), 3L)

  partial <- gm_check_solution(p, p$solution[1:2])
  expect_false(partial$correct)
  expect_equal(partial$solved_plies, 2L)

  wrong <- gm_check_solution(p, c("Ne4", "Kg8", "Nxd8"))
  expect_false(wrong$correct)
  expect_equal(wrong$solved_plies, 0L)

  half_wrong <- gm_check_solution(p, c("Nf7+", "Kh7"))
  expect_equal(half_wrong$solved_plies, 1L)
})

test_that("gm_check_solution() ignores annotation marks", {
  p <- gm_puzzle(id = "gm-0001")
  expect_true(gm_check_solution(p, "Ra8")$correct)
  expect_true(gm_check_solution(p, "Ra8#!!")$correct)
})

test_that("gm_check_solution() validates its arguments", {
  expect_error(gm_check_solution(gm_position(), "e4"), class = "rlang_error")
  expect_error(gm_check_solution(gm_puzzle(seed = 1), 42), "character vector")
})

test_that("a puzzle prints a board", {
  expect_message(print(gm_puzzle(id = "gm-0001")), "gm-0001")
  suppressMessages(expect_invisible(print(gm_puzzle(id = "gm-0001"))))
})
