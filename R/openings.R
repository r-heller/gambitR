#' Look up openings by name or moves
#'
#' Query the bundled ECO opening book.
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
gm_openings <- function(query = NULL, eco = NULL) {
  # TODO(build): load inst/extdata/eco.rds, filter by query/eco.
  tibble::tibble(eco = character(), name = character(),
                 moves = character(), fen = character())
}

#' Identify the opening of a game
#'
#' @param game A [gm_game] object.
#' @return A one-row [tibble::tibble()] with the matched `eco`, `name` and the
#'   ply at which the book line diverged (`book_depth`). Zero rows if unmatched.
#' @export
#' @family openings
#' @examples
#' gm_identify_opening(gm_read_pgn("1. e4 c5 *", text = TRUE))
gm_identify_opening <- function(game) {
  # TODO(build): walk game moves against opening book, deepest prefix match.
  tibble::tibble(eco = character(), name = character(), book_depth = integer())
}
