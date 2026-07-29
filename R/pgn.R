#' Read a game from 'PGN'
#'
#' Parse Portable Game Notation into a game object: header tags plus the
#' sequence of moves and resulting positions.
#'
#' @param file A path to a `.pgn` file, or a single character string of 'PGN'
#'   text when `text = TRUE`.
#' @param text If `TRUE`, treat `file` as literal 'PGN' text rather than a path.
#' @param call The execution environment, for error reporting. Experts only.
#' @return A [gm_game] object.
#' @export
#' @family io
#' @examples
#' pgn <- "1. e4 e5 2. Nf3 Nc6 *"
#' gm_read_pgn(pgn, text = TRUE)
gm_read_pgn <- function(file, text = FALSE, call = rlang::caller_env()) {
  if (!is.logical(text) || length(text) != 1L) {
    cli::cli_abort("{.arg text} must be {.code TRUE} or {.code FALSE}.", call = call)
  }
  # TODO(build): tokenise SAN, replay moves, build gm_game.
  new_gm_game()
}

#' Write a game to 'PGN'
#'
#' @param game A [gm_game] object.
#' @param path Optional output path. If `NULL` (default), the 'PGN' string is
#'   returned invisibly instead of being written.
#' @param overwrite If `FALSE` (default), error rather than overwrite `path`.
#' @return The 'PGN' string, invisibly. Called for its side effect when `path`
#'   is supplied.
#' @export
#' @family io
#' @examples
#' gm_write_pgn(gm_read_pgn("1. e4 e5 *", text = TRUE))
gm_write_pgn <- function(game, path = NULL, overwrite = FALSE) {
  # TODO(build): serialise game to PGN; honour overwrite guard.
  invisible("")
}
