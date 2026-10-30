test_that("gm_simulate() returns a tidy result table", {
  res <- gm_simulate(n = 2, max_moves = 5, verbose = FALSE)
  expect_s3_class(res, "tbl_df")
  expect_named(res, c("game", "result", "plies", "termination"))
  expect_equal(nrow(res), 2L)
  expect_identical(res$game, 1:2)
  expect_type(res$plies, "integer")
  expect_true(all(res$result %in% c("1-0", "0-1", "1/2-1/2")))
  expect_true(all(res$termination %in% .GM_TERMINATIONS))
})

test_that("gm_simulate() honours n", {
  res <- gm_simulate(n = 3, max_moves = 4, verbose = FALSE)
  expect_equal(nrow(res), 3L)
  expect_error(gm_simulate(n = 0), "positive whole number")
})

test_that("a random game terminates with a valid result", {
  set.seed(42)
  game <- gm_play(white = "random", black = "random", max_moves = 60, verbose = FALSE)
  expect_s3_class(game, "gm_game")
  expect_true(game$result %in% c("1-0", "0-1", "1/2-1/2"))
  expect_length(game$positions, length(game$moves) + 1L)
  expect_true(game$tags[["Termination"]] %in% .GM_TERMINATIONS)
})

test_that("every move of a simulated game is legal and replayable", {
  set.seed(7)
  game <- gm_play(white = "random", black = "random", max_moves = 40, verbose = FALSE)
  replayed <- gm_position()
  for (i in seq_along(game$moves)) {
    expect_true(game$moves[[i]] %in% gm_legal_moves(replayed)$san)
    replayed <- gm_move(replayed, game$moves[[i]])
    expect_identical(gm_write_fen(replayed), gm_write_fen(game$positions[[i + 1L]]))
  }
})

test_that("100 random games run through without error", {
  skip_on_cran()
  set.seed(1)
  res <- gm_simulate(n = 100, max_moves = 40, verbose = FALSE)
  expect_equal(nrow(res), 100L)
  expect_true(all(res$result %in% c("1-0", "0-1", "1/2-1/2")))
  expect_true(all(res$termination %in% .GM_TERMINATIONS))
  expect_true(all(res$plies >= 0L))
})

test_that("the engine strategy beats the random strategy more often than not", {
  skip_on_cran()
  set.seed(11)
  res <- gm_simulate(white = "engine", black = "random", n = 6, max_moves = 60, verbose = FALSE)
  expect_gte(sum(res$result == "1-0"), sum(res$result == "0-1"))
})

test_that("checkmate ends the game with the right result", {
  pos <- gm_position("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1")
  game <- gm_play(white = "engine", black = "random", position = pos, verbose = FALSE)
  expect_identical(game$result, "1-0")
  expect_identical(game$tags[["Termination"]], "checkmate")
  expect_identical(game$moves, "Ra8#")
})

test_that("stalemate is adjudicated as a draw", {
  pos <- gm_position("7k/2Q5/6K1/8/8/8/8/8 w - - 0 1")
  game <- gm_play(
    white = function(p) "Qf7", black = "random",
    position = pos, verbose = FALSE
  )
  expect_identical(game$tags[["Termination"]], "stalemate")
  expect_identical(game$result, "1/2-1/2")
})

test_that("the fifty-move rule and insufficient material stop a game", {
  fifty <- gm_position("8/8/4k3/8/8/4K3/8/7R w - - 100 80")
  game <- gm_play(white = "random", black = "random", position = fifty, verbose = FALSE)
  expect_identical(game$tags[["Termination"]], "fifty-move")
  expect_identical(game$result, "1/2-1/2")

  bare <- gm_position("8/8/4k3/8/8/4K3/8/8 w - - 0 1")
  bare_game <- gm_play(white = "random", black = "random", position = bare, verbose = FALSE)
  expect_identical(bare_game$tags[["Termination"]], "insufficient material")
})

test_that("threefold repetition is detected", {
  pos <- gm_position("7k/8/8/8/8/8/8/R6K w - - 0 1")
  shuffle <- local({
    i <- 0L
    function(p) {
      i <<- i + 1L
      c("Ra2", "Kg8", "Ra1", "Kh8", "Ra2", "Kg8", "Ra1", "Kh8")[[(i - 1L) %% 8L + 1L]]
    }
  })
  game <- gm_play(white = shuffle, black = shuffle, position = pos, verbose = FALSE)
  expect_identical(game$tags[["Termination"]], "threefold")
  expect_identical(game$result, "1/2-1/2")
})

test_that("the move limit adjudicates a draw", {
  game <- gm_play(white = "random", black = "random", max_moves = 3, verbose = FALSE)
  expect_identical(game$tags[["Termination"]], "move limit")
  expect_length(game$moves, 6L)
})

test_that("strategies are validated", {
  expect_error(gm_play(white = "psychic", verbose = FALSE), "Unknown strategy")
  expect_error(gm_play(white = 42, verbose = FALSE), "must be a function")
  expect_error(gm_play(position = "start"), class = "rlang_error")
  expect_error(gm_play(max_moves = 0), "positive whole number")
  expect_error(
    gm_play(white = function(p) 42, black = "random", verbose = FALSE),
    "must return a single move"
  )
})

test_that("a played game serialises to PGN and back", {
  set.seed(3)
  game <- gm_play(white = "random", black = "random", max_moves = 12, verbose = FALSE)
  pgn <- gm_write_pgn(game)
  expect_identical(gm_read_pgn(pgn, text = TRUE)$moves, game$moves)
})

test_that("gm_play() reports progress when verbose", {
  expect_message(
    gm_play(white = "random", black = "random", max_moves = 1, verbose = TRUE),
    "after"
  )
})
