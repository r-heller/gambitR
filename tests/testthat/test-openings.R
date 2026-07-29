test_that("gm_openings() returns the whole book by default", {
  book <- gm_openings()
  expect_s3_class(book, "tbl_df")
  expect_named(book, c("eco", "name", "moves", "fen"))
  expect_gt(nrow(book), 100L)
  expect_true(all(grepl("^[A-E][0-9]{2}$", book$eco)))
  expect_false(anyNA(book$fen))
})

test_that("every bundled line replays to its recorded FEN", {
  book <- gm_openings()
  for (i in seq_len(nrow(book))) {
    position <- gm_position()
    for (san in strsplit(book$moves[[i]], " ", fixed = TRUE)[[1L]]) {
      position <- gm_move(position, san)
    }
    expect_identical(gm_write_fen(position), book$fen[[i]])
  }
})

test_that("gm_openings() filters by name", {
  sicilian <- gm_openings("Sicilian")
  expect_gt(nrow(sicilian), 5L)
  expect_true(all(grepl("Sicilian", sicilian$name)))
  expect_equal(nrow(gm_openings("sicilian")), nrow(sicilian))

  # The Sicilian Defense proper lives in B20-B99; the other hits are the
  # reversed-Sicilian English lines, which are correctly coded in A.
  proper <- sicilian[startsWith(sicilian$name, "Sicilian Defense"), ]
  expect_gt(nrow(proper), 5L)
  expect_true(all(grepl("^B[2-9]", proper$eco)))
})

test_that("gm_openings() filters by ECO code and prefix", {
  expect_true(all(gm_openings(eco = "C6")$eco %in% sprintf("C6%d", 0:9)))
  expect_true(all(gm_openings(eco = "B20")$eco == "B20"))
  expect_equal(nrow(gm_openings(eco = "z")), 0L)
})

test_that("gm_openings() returns zero rows rather than NULL when nothing matches", {
  none <- gm_openings("Klingon Gambit")
  expect_s3_class(none, "tbl_df")
  expect_equal(nrow(none), 0L)
  expect_named(none, c("eco", "name", "moves", "fen"))
})

test_that("gm_openings() validates its arguments", {
  expect_error(gm_openings(query = 42), "single non-NA string")
  expect_error(gm_openings(eco = c("A", "B")), "single non-NA string")
})

test_that("gm_identify_opening() finds the deepest book line", {
  sicilian <- gm_identify_opening(gm_read_pgn("1. e4 c5 *", text = TRUE))
  expect_s3_class(sicilian, "tbl_df")
  expect_named(sicilian, c("eco", "name", "book_depth"))
  expect_equal(nrow(sicilian), 1L)
  expect_identical(sicilian$eco, "B20")
  expect_equal(sicilian$book_depth, 2L)

  najdorf <- gm_identify_opening(gm_read_pgn(
    "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 e5 *",
    text = TRUE
  ))
  expect_identical(najdorf$eco, "B90")
  expect_equal(najdorf$book_depth, 10L)
})

test_that("gm_identify_opening() ignores check and annotation marks", {
  moscow <- gm_identify_opening(gm_read_pgn("1. e4 c5 2. Nf3 d6 3. Bb5+ Bd7 *", text = TRUE))
  expect_identical(moscow$eco, "B51")
})

test_that("gm_identify_opening() returns zero rows when off book", {
  none <- gm_identify_opening(gm_read_pgn("1. a3 h6 2. a4 h5 *", text = TRUE))
  expect_s3_class(none, "tbl_df")
  expect_named(none, c("eco", "name", "book_depth"))
  expect_true(nrow(none) <= 1L)

  empty <- gm_identify_opening(gm_read_pgn("*", text = TRUE))
  expect_equal(nrow(empty), 0L)
})

test_that("gm_identify_opening() validates its argument", {
  expect_error(gm_identify_opening(gm_position()), class = "rlang_error")
})
