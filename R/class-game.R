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
  cli::cli_text("{.cls gm_game} \u2014 {length(x$moves)} half-move{?s}, result {.val {x$result}}")
  invisible(x)
}
