test_that("the starting position parses to the expected board", {
  pos <- gm_position()
  expect_length(pos$board, 64L)
  expect_equal(pos$board[1:8], c("r", "n", "b", "q", "k", "b", "n", "r"))
  expect_equal(pos$board[57:64], c("R", "N", "B", "Q", "K", "B", "N", "R"))
  expect_true(all(pos$board[17:48] == "."))
  expect_equal(pos$turn, "w")
  expect_equal(pos$castling, "KQkq")
  expect_true(is.na(pos$ep))
  expect_equal(pos$halfmove, 0L)
  expect_equal(pos$fullmove, 1L)
})

test_that("gm_write_fen() inverts gm_read_fen()", {
  fens <- c(
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
    "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
    "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
    "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
    "rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2"
  )
  for (fen in fens) {
    expect_identical(gm_write_fen(gm_read_fen(fen)), fen)
  }
})

test_that("a position survives a write / read round trip", {
  pos <- gm_move(gm_move(gm_position(), "e4"), "c5")
  expect_identical(gm_write_fen(gm_read_fen(gm_write_fen(pos))), gm_write_fen(pos))
})

test_that("the halfmove and fullmove fields may be omitted", {
  pos <- gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -")
  expect_equal(pos$halfmove, 0L)
  expect_equal(pos$fullmove, 1L)
})

test_that("stale castling rights are pruned", {
  pos <- gm_read_fen("4k3/8/8/8/8/8/8/4K2R w KQkq - 0 1")
  expect_identical(pos$castling, "K")
})

test_that("malformed FEN is rejected with an informative message", {
  expect_snapshot(error = TRUE, {
    gm_read_fen(42)
    gm_read_fen("not a fen")
    gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP w KQkq - 0 1")
    gm_read_fen("rnbqkbnr/ppppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR x KQkq - 0 1")
    gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQXq - 0 1")
    gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq e4 0 1")
    gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - x 1")
    gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0")
  })
})

test_that("impossible positions are rejected", {
  expect_error(gm_read_fen("8/8/8/8/8/8/8/8 w - - 0 1"), "one king per side")
  expect_error(gm_read_fen("4k3/4R3/8/8/8/8/8/4K3 w - - 0 1"), "not to move is in check")
})

test_that("gm_position() accepts a FEN and defaults to the start", {
  expect_identical(gm_write_fen(gm_position()), gm_write_fen(gm_position(NULL)))
  expect_identical(
    gm_write_fen(gm_position("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1")),
    "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1"
  )
})

test_that("print.gm_position() renders an 8x8 board", {
  lines <- .gm_format_board(gm_position())
  expect_length(lines, 9L)
  expect_match(lines[1L], "^8")
  expect_match(lines[8L], "^1")
  expect_match(lines[9L], "a b c d e f g h")
  flipped <- .gm_format_board(gm_position(), flip = TRUE)
  expect_match(flipped[1L], "^1")
  expect_match(flipped[9L], "h g f e d c b a")
  expect_message(print(gm_position()), "White to move")
  suppressMessages(expect_invisible(print(gm_position())))
})
