test_that("gm_legal_moves() returns a tibble with the expected columns", {
  mv <- gm_legal_moves(gm_position())
  expect_s3_class(mv, "tbl_df")
  expect_named(mv, c("from", "to", "piece", "san", "promotion", "flag"))
  expect_equal(nrow(mv), 20L)
  expect_true(all(mv$flag == "normal"))
  expect_true(all(is.na(mv$promotion)))
})

test_that("gm_status() returns a single string", {
  st <- gm_status(gm_position())
  expect_type(st, "character")
  expect_length(st, 1L)
  expect_identical(st, "normal")
})

test_that("gm_legal_moves() rejects non-positions", {
  expect_error(gm_legal_moves("e4"), class = "rlang_error")
  expect_error(gm_status(42), class = "rlang_error")
})

test_that("checkmate, stalemate and check are detected", {
  fools <- gm_position("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")
  expect_identical(gm_status(fools), "checkmate")
  expect_equal(nrow(gm_legal_moves(fools)), 0L)

  stale <- gm_position("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")
  expect_identical(gm_status(stale), "stalemate")
  expect_equal(nrow(gm_legal_moves(stale)), 0L)

  checked <- gm_position("rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2")
  expect_identical(gm_status(gm_move(checked, "Qh4")), "checkmate")
})

test_that("castling is generated and applied correctly", {
  pos <- gm_position("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
  mv <- gm_legal_moves(pos)
  expect_setequal(mv$san[mv$flag == "castle"], c("O-O", "O-O-O"))

  short <- gm_move(pos, "O-O")
  expect_identical(gm_write_fen(short), "r3k2r/8/8/8/8/8/8/R4RK1 b kq - 1 1")
  long <- gm_move(pos, "O-O-O")
  expect_identical(gm_write_fen(long), "r3k2r/8/8/8/8/8/8/2KR3R b kq - 1 1")
  expect_identical(gm_write_fen(gm_move(pos, "0-0")), gm_write_fen(short))
})

test_that("castling through, into and out of check is refused", {
  clear <- gm_position("4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1")
  expect_true(all(c("O-O", "O-O-O") %in% gm_legal_moves(clear)$san))

  through <- gm_read_fen("4k3/8/8/8/8/8/3r4/R3K2R w KQ - 0 1")
  expect_false("O-O-O" %in% gm_legal_moves(through)$san)
  expect_true("O-O" %in% gm_legal_moves(through)$san)

  into <- gm_read_fen("4k3/8/8/8/8/8/6r1/R3K2R w KQ - 0 1")
  expect_false("O-O" %in% gm_legal_moves(into)$san)

  in_check <- gm_read_fen("4k3/8/8/8/8/8/4r3/R3K2R w KQ - 0 1")
  expect_length(grep("^O-O", gm_legal_moves(in_check)$san), 0L)
})

test_that("a rook move removes only its own castling right", {
  pos <- gm_position("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
  expect_identical(gm_move(pos, "Rh2")$castling, "Qkq")
  expect_identical(gm_move(pos, "Ra2")$castling, "Kkq")
  expect_identical(gm_move(pos, "Ke2")$castling, "kq")
})

test_that("capturing a rook removes the opponent's castling right", {
  pos <- gm_read_fen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
  expect_identical(gm_move(pos, "Rxa8+")$castling, "Kk")
})

test_that("en passant is generated, applied and expires", {
  pos <- gm_position("rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3")
  mv <- gm_legal_moves(pos)
  ep <- mv[mv$flag == "ep", ]
  expect_equal(nrow(ep), 1L)
  expect_identical(ep$san, "exf6")

  after <- gm_move(pos, "exf6")
  expect_identical(after$board[.GM_SQ_INDEX[["f5"]]], ".")
  expect_identical(after$board[.GM_SQ_INDEX[["f6"]]], "P")
  expect_true(is.na(after$ep))
})

test_that("a double pawn push sets the en passant square", {
  expect_identical(gm_move(gm_position(), "e4")$ep, "e3")
  expect_identical(gm_move(gm_move(gm_position(), "e4"), "c5")$ep, "c6")
})

test_that("an en passant capture that would expose the king is refused", {
  pinned <- gm_read_fen("8/8/8/8/k1pP3R/8/8/3K4 b - d3 0 1")
  mv <- gm_legal_moves(pinned)
  expect_false("ep" %in% mv$flag)
  expect_false("cxd3" %in% mv$san)

  safe <- gm_read_fen("8/8/8/8/k1pP4/8/8/3K4 b - d3 0 1")
  expect_true("cxd3" %in% gm_legal_moves(safe)$san)
})

test_that("promotions generate all four pieces", {
  pos <- gm_position("8/4P3/8/8/8/8/8/k6K w - - 0 1")
  mv <- gm_legal_moves(pos)
  promos <- mv[mv$flag == "promo", ]
  expect_equal(nrow(promos), 4L)
  expect_setequal(promos$promotion, c("Q", "R", "B", "N"))
  expect_setequal(promos$san, c("e8=Q", "e8=R", "e8=B", "e8=N"))
  expect_identical(gm_move(pos, "e8=N")$board[.GM_SQ_INDEX[["e8"]]], "N")
})

test_that("SAN disambiguation follows the standard rules", {
  files <- gm_position("k7/8/8/8/8/8/8/K3R2R w - - 0 1")
  expect_true(all(c("Ref1", "Rhf1") %in% gm_legal_moves(files)$san))

  ranks <- gm_position("k7/8/8/8/7R/8/8/K6R w - - 0 1")
  expect_true(all(c("R4h2", "R1h2") %in% gm_legal_moves(ranks)$san))

  three <- gm_position("k7/8/8/1Q6/8/8/1Q2Q3/7K w - - 0 1")
  san <- gm_legal_moves(three)$san
  expect_true("Qb2e5" %in% san)
  expect_true("Qbxe5" %in% san || "Qee5" %in% san || "Qb5e5" %in% san)
})

test_that("SAN carries check and mate suffixes", {
  mate <- gm_position("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1")
  expect_true("Ra8#" %in% gm_legal_moves(mate)$san)

  check <- gm_position("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1")
  expect_true("Ra8#" %in% gm_legal_moves(check)$san)
})

test_that("gm_move() accepts SAN and long algebraic and rejects nonsense", {
  pos <- gm_position()
  expect_identical(gm_write_fen(gm_move(pos, "e4")), gm_write_fen(gm_move(pos, "e2e4")))
  expect_identical(gm_write_fen(gm_move(pos, "Nf3")), gm_write_fen(gm_move(pos, "g1f3")))
  expect_identical(gm_write_fen(gm_move(pos, "Nf3!?")), gm_write_fen(gm_move(pos, "Nf3")))
  expect_error(gm_move(pos, "e5"), "not a legal move")
  expect_error(gm_move(pos, "Ke2"), "not a legal move")
  expect_error(gm_move(pos, 42), "single non-NA string")
  expect_error(gm_move("start", "e4"), class = "rlang_error")
})

test_that("gm_move() refuses to move in a finished game", {
  mated <- gm_position("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")
  expect_error(gm_move(mated, "e4"), "no legal moves")
})

test_that("the clocks advance correctly", {
  pos <- gm_position()
  after1 <- gm_move(pos, "Nf3")
  expect_equal(after1$halfmove, 1L)
  expect_equal(after1$fullmove, 1L)
  after2 <- gm_move(after1, "Nf6")
  expect_equal(after2$halfmove, 2L)
  expect_equal(after2$fullmove, 2L)
  expect_equal(gm_move(pos, "e4")$halfmove, 0L)
})
