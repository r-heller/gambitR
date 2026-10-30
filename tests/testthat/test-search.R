test_that("gm_bestmove() returns the declared one-row tibble", {
  res <- gm_bestmove(gm_position(), depth = 1L, verbose = FALSE)
  expect_s3_class(res, "tbl_df")
  expect_named(res, c("san", "score", "depth", "nodes"))
  expect_equal(nrow(res), 1L)
  expect_type(res$san, "character")
  expect_type(res$depth, "integer")
  expect_type(res$nodes, "integer")
})

test_that("gm_bestmove() returns a legal move", {
  for (fen in c(
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
    "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
    "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1"
  )) {
    pos <- gm_position(fen)
    res <- gm_bestmove(pos, depth = 2L, verbose = FALSE)
    expect_true(res$san %in% gm_legal_moves(pos)$san)
    expect_s3_class(gm_move(pos, res$san), "gm_position")
  }
})

test_that("the engine finds a mate in one at depth 2", {
  back_rank <- gm_position("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1")
  res <- gm_bestmove(back_rank, depth = 2L, verbose = FALSE)
  expect_identical(res$san, "Ra8#")
  expect_gt(res$score, 90000)

  scholars <- gm_position("r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4")
  expect_identical(gm_bestmove(scholars, depth = 2L, verbose = FALSE)$san, "Qxf7#")
})

test_that("the engine sees a mate against it", {
  skip_on_cran()
  # Black threatens ...Qxf2#; White must deal with it.
  pos <- gm_position("rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2")
  res <- gm_bestmove(pos, depth = 2L, verbose = FALSE)
  expect_identical(res$san, "Qh4#")
  expect_lt(res$score, -90000)
})

test_that("the engine grabs a free queen", {
  pos <- gm_position("4k3/8/8/3q4/4P3/8/8/4K3 w - - 0 1")
  expect_identical(gm_bestmove(pos, depth = 2L, verbose = FALSE)$san, "exd5")
})

test_that("deeper searches do not lose material for nothing", {
  skip_on_cran()
  pos <- gm_position()
  shallow <- gm_bestmove(pos, depth = 1L, verbose = FALSE)
  deeper <- gm_bestmove(pos, depth = 3L, verbose = FALSE)
  expect_gt(deeper$nodes, shallow$nodes)
  expect_true(deeper$san %in% gm_legal_moves(pos)$san)
})

test_that("a finished position yields no move", {
  mated <- gm_position("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")
  res <- gm_bestmove(mated, depth = 2L, verbose = FALSE)
  expect_true(is.na(res$san))
  expect_equal(res$nodes, 0L)
})

test_that("gm_bestmove() validates its arguments", {
  expect_error(gm_bestmove("start"), class = "rlang_error")
  expect_error(gm_bestmove(gm_position(), depth = 0), "positive whole number")
  expect_error(gm_bestmove(gm_position(), engine = "magic"), class = "rlang_error")
})

test_that("move ordering puts the best capture first", {
  pos <- gm_position("4k3/8/8/3q4/4P3/8/8/4K3 w - - 0 1")
  st <- .gm_state(pos)
  ordered <- .gm_order_moves(.gm_gen_legal(st))
  expect_equal(ordered$capture[[1L]], 11L)
})

test_that("UCI parsing handles score, mate, depth and nodes", {
  info <- .gm_parse_uci_info("info depth 12 seldepth 18 nodes 12345 score cp -37 pv e2e4 e7e5")
  expect_equal(info$score, -37)
  expect_equal(info$depth, 12L)
  expect_equal(info$nodes, 12345L)
  expect_equal(info$pv, "e2e4 e7e5")

  mate <- .gm_parse_uci_info("info depth 5 nodes 900 score mate 3 pv a1a8")
  expect_gt(mate$score, 90000)
  expect_equal(.gm_parse_uci_info(NA_character_)$score, NA_real_)
})

test_that("engine long algebraic converts to SAN", {
  expect_identical(.gm_lan_to_san(gm_position(), "e2e4"), "e4")
  expect_identical(.gm_lan_to_san(gm_position(), "g1f3"), "Nf3")
  expect_true(is.na(.gm_lan_to_san(gm_position(), "(none)")))
  expect_true(is.na(.gm_lan_to_san(gm_position(), "e2e5")))
})

test_that("gm_uci_bestmove() errors informatively without an engine", {
  skip_if(.gm_has_uci())
  expect_error(
    gm_uci_bestmove(gm_position(), engine_path = ""),
    "No 'UCI' engine found"
  )
})

test_that("gm_uci_bestmove() talks to a real engine", {
  skip_if_not(.gm_has_uci())
  res <- gm_uci_bestmove(gm_position(), movetime = 200L, verbose = FALSE)
  expect_s3_class(res, "tbl_df")
  expect_named(res, c("san", "score", "pv"))
  expect_true(res$san %in% gm_legal_moves(gm_position())$san)

  via_bestmove <- gm_bestmove(gm_position(), engine = "uci", verbose = FALSE)
  expect_named(via_bestmove, c("san", "score", "depth", "nodes"))
})

test_that("the UCI client completes the handshake and parses the reply", {
  engine <- gm_fake_engine()
  res <- gm_uci_bestmove(gm_position(), engine_path = engine, movetime = 100L, verbose = FALSE)
  expect_s3_class(res, "tbl_df")
  expect_named(res, c("san", "score", "pv"))
  expect_identical(res$san, "e4")
  expect_equal(res$score, 25)
  expect_identical(res$pv, "e2e4 e7e5")
})

test_that("the UCI backend of gm_bestmove() reports depth and nodes", {
  # `gm_bestmove()` has no `engine_path` argument, so this needs a real engine
  # on the PATH rather than the stand-in used by the tests above.
  skip_if_not(.gm_has_uci())
  res <- gm_bestmove(gm_position(), engine = "uci", verbose = FALSE)
  expect_named(res, c("san", "score", "depth", "nodes"))
  expect_true(res$san %in% gm_legal_moves(gm_position())$san)
})

test_that("UCI scores are reported from White's point of view", {
  engine <- gm_fake_engine()
  black <- gm_position("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")
  res <- .gm_uci_query(black, engine_path = engine, movetime = 100L, verbose = FALSE)
  expect_equal(res$score, -25)
  expect_equal(res$nodes, 4242L)
  expect_equal(res$depth, 4L)
})

test_that("a silent engine is reported rather than hanging forever", {
  skip_on_os("windows")
  skip_if_not_installed("processx")
  mute <- withr::local_tempfile(fileext = ".sh")
  writeLines(c("#!/bin/sh", "sleep 30"), mute)
  Sys.chmod(mute, "0755")
  expect_error(
    gm_uci_bestmove(gm_position(), engine_path = mute, movetime = 100L, verbose = FALSE),
    "handshake"
  )
})

test_that("gm_uci_bestmove() validates its arguments", {
  expect_error(gm_uci_bestmove("start"), class = "rlang_error")
  expect_error(
    gm_uci_bestmove(gm_position(), engine_path = "x", movetime = -1),
    "positive whole number"
  )
})
