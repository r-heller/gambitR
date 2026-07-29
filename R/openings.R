# Bundled reference data is read once and kept for the session.
.gm_cache <- new.env(parent = emptyenv())

#' @noRd
.gm_extdata <- function(file, empty) {
  if (is.null(.gm_cache[[file]])) {
    path <- system.file("extdata", file, package = "gambitR")
    .gm_cache[[file]] <- if (nzchar(path) && file.exists(path)) {
      readRDS(path)
    } else {
      empty
    }
  }
  .gm_cache[[file]]
}

#' @noRd
.gm_empty_book <- function() {
  tibble::tibble(
    eco = character(0L), name = character(0L),
    moves = character(0L), fen = character(0L)
  )
}

#' @noRd
.gm_book <- function() {
  .gm_extdata("eco.rds", .gm_empty_book())
}

# Book lines and game moves are compared without check, mate or annotation
# marks so that notation from different sources still lines up.
#' @noRd
.gm_bare_san <- function(x) {
  gsub("[+#!?]", "", x)
}

#' Look up openings by name or moves
#'
#' Query the bundled ECO opening book.
#'
#' The book ships with the package as `inst/extdata/eco.rds` and is built by
#' `data-raw/eco.R`, which replays every line through [gm_move()] so that no
#' unplayable sequence can reach it. `eco` is matched as a prefix, so
#' `eco = "B2"` returns the whole of the B20-B29 range.
#'
#' @param query A search string matched against opening names (e.g.
#'   `"Sicilian"`), or `NULL` (default) to return the whole book.
#' @param eco Optional ECO code filter (e.g. `"B20"`).
#' @return A [tibble::tibble()] with columns `eco` (character), `name`
#'   (character), `moves` (character, space-separated SAN) and `fen`
#'   (character, resulting position). Zero rows when nothing matches.
#' @export
#' @family openings
#' @examples
#' gm_openings("Sicilian")
#' gm_openings(eco = "C6")
gm_openings <- function(query = NULL, eco = NULL) {
  book <- .gm_book()
  if (!is.null(query)) {
    if (!is.character(query) || length(query) != 1L || is.na(query)) {
      cli::cli_abort("{.arg query} must be a single non-NA string or {.code NULL}.")
    }
    book <- book[grepl(query, book$name, ignore.case = TRUE), , drop = FALSE]
  }
  if (!is.null(eco)) {
    if (!is.character(eco) || length(eco) != 1L || is.na(eco)) {
      cli::cli_abort("{.arg eco} must be a single non-NA string or {.code NULL}.")
    }
    keep <- startsWith(book$eco, toupper(eco))
    book <- book[keep, , drop = FALSE]
  }
  book
}

#' Identify the opening of a game
#'
#' Walk the game's moves against the bundled book and report the deepest line
#' that the game follows.
#'
#' @param game A [gm_game] object.
#' @return A one-row [tibble::tibble()] with the matched `eco`, `name` and the
#'   ply at which the book line diverged (`book_depth`). Zero rows if unmatched.
#' @export
#' @family openings
#' @examples
#' gm_identify_opening(gm_read_pgn("1. e4 c5 *", text = TRUE))
gm_identify_opening <- function(game) {
  if (!is_gm_game(game)) {
    cli::cli_abort("{.arg game} must be a {.cls gm_game} object.")
  }
  empty <- tibble::tibble(
    eco = character(0L), name = character(0L), book_depth = integer(0L)
  )
  book <- .gm_book()
  if (nrow(book) == 0L || length(game$moves) == 0L) {
    return(empty)
  }
  played <- .gm_bare_san(game$moves)
  depth <- integer(nrow(book))
  for (i in seq_len(nrow(book))) {
    line <- .gm_bare_san(strsplit(book$moves[[i]], " ", fixed = TRUE)[[1L]])
    n <- length(line)
    depth[[i]] <- if (n <= length(played) && all(line == played[seq_len(n)])) n else 0L
  }
  if (max(depth) == 0L) {
    return(empty)
  }
  best <- which.max(depth)
  tibble::tibble(
    eco = book$eco[[best]],
    name = book$name[[best]],
    book_depth = depth[[best]]
  )
}
