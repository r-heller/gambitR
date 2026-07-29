#' Chess games
#'
#' A `gm_game` is the S3 container returned by [gm_read_pgn()], [gm_play()]
#' and the study tools. It is a list with four elements:
#'
#' \describe{
#'   \item{`moves`}{Character vector of mainline moves in standard algebraic
#'     notation, one per half-move.}
#'   \item{`positions`}{List of [gm_position] objects, one longer than
#'     `moves`: the starting position followed by the position after each
#'     move.}
#'   \item{`tags`}{Named list of 'PGN' header tags, e.g. `Event` or `White`.}
#'   \item{`result`}{One of `"1-0"`, `"0-1"`, `"1/2-1/2"` or `"*"`.}
#' }
#'
#' Use [is_gm_game()] to test for the class, [gm_write_pgn()] to serialise it
#' and [gm_plot_eval()] to visualise how the evaluation moved.
#'
#' @name gm_game
#' @family core
#' @examples
#' game <- gm_read_pgn("1. e4 e5 2. Nf3 Nc6 *", text = TRUE)
#' game$moves
#' game$result
NULL

#' @noRd
new_gm_game <- function(moves = character(), positions = list(),
                        tags = list(), result = "*") {
  structure(
    list(moves = moves, positions = positions, tags = tags, result = result),
    class = "gm_game"
  )
}

#' Test whether an object is a chess game
#'
#' @param x An object to test.
#' @return A logical scalar.
#' @export
#' @family core
#' @examples
#' is_gm_game(gm_read_pgn("1. e4 e5 *", text = TRUE))
is_gm_game <- function(x) {
  inherits(x, "gm_game")
}

#' @export
print.gm_game <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_text(
    "{.cls gm_game} \u2014 {length(x$moves)} half-move{?s}, result {.val {x$result}}"
  )
  players <- c(x$tags[["White"]] %||% NA_character_, x$tags[["Black"]] %||% NA_character_)
  if (!anyNA(players)) {
    cli::cli_text("{.field {players[1]}} vs {.field {players[2]}}")
  }
  if (length(x$moves)) {
    shown <- utils::head(x$moves, 12L)
    body <- .gm_pgn_movetext(shown, if (length(x$moves) > 12L) "..." else x$result)
    cli::cli_verbatim(body)
  }
  invisible(x)
}
