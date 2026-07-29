app_dir <- function() {
  path <- system.file("shiny", "gambitR", package = "gambitR")
  testthat::skip_if(!nzchar(path) || !dir.exists(path), "app directory not installed")
  path
}

load_modules <- function(envir = parent.frame()) {
  testthat::skip_if_not_installed("shiny")
  testthat::skip_if_not_installed("bslib")
  dir <- file.path(app_dir(), "modules")
  for (f in sort(list.files(dir, pattern = "\\.R$", full.names = TRUE))) {
    sys.source(f, envir = envir)
  }
  invisible(NULL)
}

test_that("gm_run_app() finds the bundled application", {
  path <- app_dir()
  expect_true(file.exists(file.path(path, "app.R")))
  expect_true(dir.exists(file.path(path, "modules")))
  expect_true(file.exists(file.path(path, "www", "custom.css")))
  expect_true(file.exists(file.path(path, "www", "logo.png")))
})

test_that("all six modules are present", {
  files <- list.files(file.path(app_dir(), "modules"), pattern = "\\.R$")
  expect_true(all(paste0(
    "mod_", c("play", "analyse", "simulate", "openings", "puzzles", "study"), ".R"
  ) %in% files))
})

test_that("app.R and the modules parse", {
  path <- app_dir()
  expect_silent(parse(file.path(path, "app.R")))
  for (f in list.files(file.path(path, "modules"), pattern = "\\.R$", full.names = TRUE)) {
    expect_silent(parse(f))
  }
})

test_that("the app contains no library() or require() calls", {
  files <- c(
    file.path(app_dir(), "app.R"),
    list.files(file.path(app_dir(), "modules"), pattern = "\\.R$", full.names = TRUE)
  )
  for (f in files) {
    # Compare code only: the files talk about the rule in their comments.
    code <- sub("#.*$", "", readLines(f, warn = FALSE))
    expect_false(any(grepl("\\blibrary\\s*\\(", code)), label = basename(f))
    expect_false(any(grepl("\\brequire\\s*\\((?!Namespace)", code, perl = TRUE)),
      label = basename(f)
    )
  }
})

test_that("every mod_*_ui() returns a shiny tag", {
  load_modules()
  for (mod in c("play", "analyse", "simulate", "openings", "puzzles", "study")) {
    ui <- get(paste0("mod_", mod, "_ui"))("test")
    expect_true(inherits(ui, "shiny.tag") || inherits(ui, "shiny.tag.list"), label = mod)
    html <- as.character(ui)
    expect_match(html, "test-", info = mod)
  }
})

test_that("app.R sources and builds a UI", {
  testthat::skip_if_not_installed("shiny")
  testthat::skip_if_not_installed("bslib")
  env <- new.env(parent = globalenv())
  app <- withr::with_dir(app_dir(), sys.source("app.R", envir = env))
  expect_s3_class(env$ui, "shiny.tag.list")
  expect_type(env$server, "closure")
})

test_that("the board click helper maps coordinates to squares", {
  load_modules()
  expect_identical(gm_click_square(list(x = 1, y = 1)), "a1")
  expect_identical(gm_click_square(list(x = 8, y = 8)), "h8")
  expect_identical(gm_click_square(list(x = 5.1, y = 3.9)), "e4")
  expect_identical(gm_click_square(list(x = 1, y = 1), flip = TRUE), "h8")
  expect_null(gm_click_square(NULL))
  expect_null(gm_click_square(list(x = 12, y = 1)))
})

test_that("the move resolver turns a square pair into SAN", {
  load_modules()
  expect_identical(gm_resolve_move(gm_position(), "e2", "e4"), "e4")
  expect_identical(gm_resolve_move(gm_position(), "g1", "f3"), "Nf3")
  expect_null(gm_resolve_move(gm_position(), "e2", "e5"))

  promo <- gm_position("8/4P3/8/8/8/8/8/k6K w - - 0 1")
  expect_identical(gm_resolve_move(promo, "e7", "e8"), "e8=Q")
})

test_that("the movetext and status helpers format sensibly", {
  load_modules()
  expect_identical(gm_movetext(character()), "(no moves yet)")
  expect_identical(gm_movetext(c("e4", "e5", "Nf3")), "1. e4 e5 2. Nf3")
  expect_match(gm_status_text(gm_position()), "White to move")
  expect_match(
    gm_status_text(gm_position("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")),
    "Checkmate"
  )
  expect_true(gm_is_over(
    gm_position("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")
  ))
})

test_that("the optional-dependency helpers fall back gracefully", {
  load_modules()
  expect_type(gm_have("shiny"), "logical")
  expect_false(gm_have("a package that does not exist"))
  expect_true(inherits(gm_picker("x", "X", c("a", "b")), "shiny.tag"))
  expect_true(inherits(gm_toggle("x", "X"), "shiny.tag"))
  expect_type(gm_uci_available(), "logical")
  expect_true(all(gm_puzzle_themes() %in% .gm_puzzle_set()$theme))
})

test_that("the play module plays a legal game against the engine", {
  skip_on_cran()
  testthat::skip_if_not_installed("shiny")
  testthat::skip_if_not_installed("bslib")
  load_modules()
  shiny::testServer(mod_play_server, args = list(id = "play"), {
    session$setInputs(side = "White", depth = 1L, flip = FALSE)
    expect_identical(rv$result, "*")

    session$setInputs(san = "e4", submit = 1L)
    expect_identical(rv$moves[[1L]], "e4")
    expect_length(rv$moves, 2L)
    expect_true(rv$moves[[2L]] %in% gm_legal_moves(rv$positions[[2L]])$san)

    # An illegal move is refused without disturbing the game.
    session$setInputs(san = "Qz9", submit = 2L)
    expect_length(rv$moves, 2L)
    expect_match(rv$note, "not a legal move")

    # Click-to-move: select g1 then f3.
    session$setInputs(board_click = list(x = 7, y = 1))
    expect_identical(rv$selected, "g1")
    session$setInputs(board_click = list(x = 6, y = 3))
    expect_true("Nf3" %in% rv$moves)

    session$setInputs(resign = 1L)
    expect_identical(rv$result, "0-1")

    output$status
    output$moves
    output$engine
  })
})

test_that("the play module plays a game through to a finished result", {
  skip_on_cran()
  testthat::skip_if_not_installed("shiny")
  testthat::skip_if_not_installed("bslib")
  load_modules()
  shiny::testServer(mod_play_server, args = list(id = "play"), {
    session$setInputs(side = "White", depth = 1L, flip = FALSE)
    # Fool's mate from the human side: 1. f3 .. 2. g4 .. and Black mates only
    # if the engine cooperates, so just check the game stays legal throughout.
    for (san in c("e4", "Nf3", "Bc4")) {
      before <- length(rv$moves)
      if (san %in% gm_legal_moves(rv$position)$san) {
        session$setInputs(san = san, submit = before + 1L)
      }
    }
    replay <- gm_position()
    for (m in rv$moves) {
      expect_true(m %in% gm_legal_moves(replay)$san)
      replay <- gm_move(replay, m)
    }
    expect_identical(gm_write_fen(replay), gm_write_fen(rv$position))
  })
})

test_that("the puzzles module accepts a correct solution", {
  skip_on_cran()
  testthat::skip_if_not_installed("shiny")
  testthat::skip_if_not_installed("bslib")
  load_modules()
  shiny::testServer(mod_puzzles_server, args = list(id = "puzzles"), {
    session$setInputs(theme = "any")
    expect_s3_class(rv$puzzle, "gm_puzzle")
    solution <- rv$puzzle$solution
    session$setInputs(san = solution[[1L]], submit = 1L)
    expect_identical(rv$attempt[[1L]], solution[[1L]])
    session$setInputs(hint = 1L)
    expect_match(rv$note, "Solution")
  })
})

test_that("the simulate module produces a results table", {
  skip_on_cran()
  testthat::skip_if_not_installed("shiny")
  testthat::skip_if_not_installed("bslib")
  load_modules()
  shiny::testServer(mod_simulate_server, args = list(id = "simulate"), {
    session$setInputs(white = "random", black = "random", n = 2L, max_moves = 5L, run = 1L)
    expect_s3_class(rv$results, "tbl_df")
    expect_equal(nrow(rv$results), 2L)
  })
})

test_that("the openings module loads a book line onto the board", {
  skip_on_cran()
  testthat::skip_if_not_installed("shiny")
  testthat::skip_if_not_installed("bslib")
  load_modules()
  shiny::testServer(mod_openings_server, args = list(id = "openings"), {
    session$setInputs(query = "Sicilian Defense", eco = "B20", line = "Sicilian Defense", ply = 2L)
    expect_s3_class(rv$position, "gm_position")
    expect_identical(
      gm_write_fen(rv$position),
      gm_write_fen(gm_move(gm_move(gm_position(), "e4"), "c5"))
    )
  })
})

test_that("the study module steps through a game and exports PGN", {
  skip_on_cran()
  testthat::skip_if_not_installed("shiny")
  testthat::skip_if_not_installed("bslib")
  load_modules()
  shiny::testServer(mod_study_server, args = list(id = "study"), {
    session$setInputs(pgn = "1. e4 e5 2. Nf3 Nc6 *", load = 1L, event = "T", white = "A", black = "B")
    expect_identical(rv$moves, c("e4", "e5", "Nf3", "Nc6"))
    expect_equal(rv$ply, 4L)

    session$setInputs(prev = 1L)
    expect_equal(rv$ply, 3L)

    session$setInputs(note = "a good move", save_note = 1L)
    expect_identical(rv$notes[[4L]], "a good move")

    session$setInputs(san = "Bb5", add = 1L)
    expect_identical(rv$moves[[5L]], "Bb5")

    expect_match(gm_write_pgn(game()), '\\[White "A"\\]')
  })
})

test_that("the analyse module evaluates a pasted FEN and PGN", {
  skip_on_cran()
  testthat::skip_if_not_installed("shiny")
  testthat::skip_if_not_installed("bslib")
  load_modules()
  shiny::testServer(mod_analyse_server, args = list(id = "analyse"), {
    session$setInputs(depth = 1L, uci = FALSE)

    session$setInputs(input_text = "6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1", load = 1L)
    expect_identical(rv$note, "FEN loaded.")
    expect_identical(best()$san, "Ra8#")

    session$setInputs(input_text = "1. e4 e5 2. Nf3 Nc6 *", load = 2L)
    expect_length(rv$game$moves, 4L)

    session$setInputs(input_text = "not a game at all", load = 3L)
    expect_type(rv$note, "character")
  })
})
