test_that("gm_evaluate() returns a single centipawn score", {
  score <- gm_evaluate(gm_position())
  expect_type(score, "double")
  expect_length(score, 1L)
  expect_equal(score, 0)
})

test_that("the evaluation is colour-symmetric", {
  fens <- c(
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
    "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
    "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
    "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
    "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4",
    "rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2"
  )
  for (fen in fens) {
    pos <- gm_position(fen)
    expect_equal(gm_evaluate(pos), -gm_evaluate(.gm_mirror_position(pos)))
  }
})

test_that("mirroring twice is the identity", {
  pos <- gm_position("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1")
  expect_identical(
    gm_write_fen(.gm_mirror_position(.gm_mirror_position(pos))),
    gm_write_fen(pos)
  )
})

test_that("material advantage dominates the score", {
  queen_up <- gm_position("rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
  expect_gt(gm_evaluate(queen_up), 800)

  rook_down <- gm_position("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/1NBQKBNR w Kkq - 0 1")
  expect_lt(gm_evaluate(rook_down), -400)
})

test_that("the piece-square tables reward development", {
  developed <- gm_position("rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b KQkq - 1 1")
  undeveloped <- gm_position()
  expect_gt(gm_evaluate(developed), gm_evaluate(undeveloped))
})

test_that("weights are merged and validated", {
  pos <- gm_position("r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4")
  expect_equal(
    gm_evaluate(pos, weights = list(mobility = 0, king_safety = 0)),
    gm_evaluate(pos, weights = list(mobility = 0, king_safety = 0, material = 1))
  )
  expect_false(identical(gm_evaluate(pos), gm_evaluate(pos, list(mobility = 0))))
  expect_error(gm_evaluate(pos, weights = list(nonsense = 1)), "Unknown weight")
  expect_error(gm_evaluate(pos, weights = 1), "named list")
  expect_error(gm_evaluate("start"), class = "rlang_error")
})

test_that("the piece-square tables cover every square and piece", {
  expect_equal(dim(.GM_PST), c(64L, 6L))
  expect_false(anyNA(.GM_PST))
  expect_true(all(.GM_PST[1:8, 1L] == 0))
  expect_true(all(.GM_PST[57:64, 1L] == 0))
})
