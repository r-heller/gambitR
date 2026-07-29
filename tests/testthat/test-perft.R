# Perft: count the leaf nodes of the move tree to a fixed depth and compare
# against the published reference values. Any mismatch means the generator is
# wrong, so these expectations are the package's primary correctness gate.

perft <- function(state, depth) {
  moves <- .gm_gen_legal(state)
  n <- length(moves$from)
  if (depth <= 1L) {
    return(n)
  }
  total <- 0
  for (i in seq_len(n)) {
    total <- total + perft(.gm_make(state, moves, i), depth - 1L)
  }
  total
}

perft_fen <- function(fen, depth) {
  perft(.gm_state(gm_position(fen)), depth)
}

startpos <- "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
kiwipete <- "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"
position3 <- "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1"
position4 <- "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1"
position5 <- "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8"

test_that("perft matches the reference counts at depth 1 and 2", {
  expect_identical(perft_fen(startpos, 1L), 20L)
  expect_identical(perft_fen(startpos, 2L), 400)
  expect_identical(perft_fen(kiwipete, 1L), 48L)
  expect_identical(perft_fen(kiwipete, 2L), 2039)
  expect_identical(perft_fen(position3, 1L), 14L)
  expect_identical(perft_fen(position3, 2L), 191)
  expect_identical(perft_fen(position4, 1L), 6L)
  expect_identical(perft_fen(position4, 2L), 264)
  expect_identical(perft_fen(position5, 1L), 44L)
  expect_identical(perft_fen(position5, 2L), 1486)
})

test_that("perft matches the reference counts at depth 3", {
  skip_on_cran()
  expect_identical(perft_fen(startpos, 3L), 8902)
  expect_identical(perft_fen(kiwipete, 3L), 97862)
  expect_identical(perft_fen(position3, 3L), 2812)
  expect_identical(perft_fen(position4, 3L), 9467)
  expect_identical(perft_fen(position5, 3L), 62379)
})

test_that("perft matches the reference counts at depth 4", {
  skip_on_cran()
  expect_identical(perft_fen(startpos, 4L), 197281)
  expect_identical(perft_fen(position3, 4L), 43238)
})

test_that("a mirrored position gives the same counts", {
  skip_on_cran()
  mirrored <- "r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ - 0 1"
  expect_identical(perft_fen(mirrored, 3L), perft_fen(position4, 3L))
})
