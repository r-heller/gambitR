morphy <- paste(
  '[Event "Paris Opera"]',
  '[Site "Paris FRA"]',
  '[Date "1858.??.??"]',
  '[Round "?"]',
  '[White "Morphy, Paul"]',
  '[Black "Duke Karl / Count Isouard"]',
  '[Result "1-0"]',
  "",
  "1. e4 e5 2. Nf3 d6 3. d4 Bg4 {A dubious pin.} 4. dxe5 Bxf3 5. Qxf3 dxe5",
  "6. Bc4 Nf6 7. Qb3 Qe7 8. Nc3 c6 9. Bg5 b5 10. Nxb5 cxb5 11. Bxb5+ Nbd7",
  "12. O-O-O Rd8 13. Rxd7 Rxd7 14. Rd1 Qe6 15. Bxd7+ Nxd7 16. Qb8+ Nxb8",
  "17. Rd8# 1-0",
  sep = "\n"
)

test_that("gm_read_pgn() parses tags, moves and result", {
  game <- gm_read_pgn(morphy, text = TRUE)
  expect_s3_class(game, "gm_game")
  expect_true(is_gm_game(game))
  expect_identical(game$tags[["White"]], "Morphy, Paul")
  expect_identical(game$tags[["Event"]], "Paris Opera")
  expect_identical(game$result, "1-0")
  expect_length(game$moves, 33L)
  expect_identical(game$moves[[1L]], "e4")
  expect_identical(game$moves[[33L]], "Rd8#")
  expect_length(game$positions, 34L)
  expect_true(all(vapply(game$positions, is_gm_position, logical(1L))))
})

test_that("a real game replays all the way to mate", {
  game <- gm_read_pgn(morphy, text = TRUE)
  final <- game$positions[[length(game$positions)]]
  expect_identical(gm_status(final), "checkmate")
  expect_identical(final$turn, "b")
})

test_that("comments, NAGs, variations and move numbers are stripped", {
  pgn <- "1. e4 {best by test} $1 e5 (1... c5 2. Nf3 d6) 2. Nf3 ; trailing\n Nc6 *"
  game <- gm_read_pgn(pgn, text = TRUE)
  expect_identical(game$moves, c("e4", "e5", "Nf3", "Nc6"))
  expect_identical(game$result, "*")
})

test_that("continuation markers and move numbers are dropped by the tokeniser", {
  expect_identical(
    .gm_tokenise_movetext("1... e5 2. Nf3 *"),
    c("e5", "Nf3", "*")
  )
  expect_identical(
    .gm_tokenise_movetext("1.e4 e5 2.Nf3 1-0"),
    c("e4", "e5", "Nf3", "1-0")
  )
})

test_that("a FEN tag sets the starting position", {
  pgn <- paste(
    '[FEN "8/4P3/8/8/8/8/8/k6K w - - 0 1"]',
    '[Result "*"]',
    "",
    "1. e8=Q *",
    sep = "\n"
  )
  game <- gm_read_pgn(pgn, text = TRUE)
  expect_identical(game$moves, "e8=Q")
  expect_identical(game$positions[[1L]]$board[.GM_SQ_INDEX[["e7"]]], "P")
})

test_that("gm_read_pgn() reports the move it could not replay", {
  expect_error(gm_read_pgn("1. e4 e5 2. Qh8 *", text = TRUE), "Could not replay move 3")
  expect_error(gm_read_pgn("x", text = 1), "must be")
  expect_error(gm_read_pgn(tempfile()), "Cannot find")
})

test_that("gm_write_pgn() round-trips the mainline", {
  game <- gm_read_pgn(morphy, text = TRUE)
  pgn <- gm_write_pgn(game)
  expect_type(pgn, "character")
  expect_match(pgn, '\\[White "Morphy, Paul"\\]')
  expect_match(pgn, "1-0\\s*$")

  again <- gm_read_pgn(pgn, text = TRUE)
  expect_identical(again$moves, game$moves)
  expect_identical(again$result, game$result)
  expect_identical(again$tags[["Black"]], game$tags[["Black"]])
})

test_that("gm_write_pgn() writes files and guards against overwriting", {
  game <- gm_read_pgn("1. e4 e5 *", text = TRUE)
  path <- withr::local_tempfile(fileext = ".pgn")
  expect_invisible(gm_write_pgn(game, path))
  expect_true(file.exists(path))
  expect_identical(gm_read_pgn(path)$moves, c("e4", "e5"))
  expect_error(gm_write_pgn(game, path), "already exists")
  expect_silent(gm_write_pgn(game, path, overwrite = TRUE))
  expect_error(gm_write_pgn("not a game"), class = "rlang_error")
})

test_that("movetext wraps and numbers correctly", {
  game <- gm_read_pgn(morphy, text = TRUE)
  body <- .gm_pgn_movetext(game$moves, game$result)
  expect_true(all(nchar(body) <= 80L))
  expect_match(body[1L], "^1\\. e4 e5 2\\. Nf3")
})

test_that("an empty game prints and serialises", {
  game <- gm_read_pgn("*", text = TRUE)
  expect_length(game$moves, 0L)
  expect_message(print(game), "0 half-moves")
  expect_match(gm_write_pgn(game), "\\*")
})
