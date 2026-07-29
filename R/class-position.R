# The `gm_position` class.
#
# Board encoding (mirrored in tables.R, which owns the lookup tables):
# `board` is a length-64 character vector indexed 1 = a8, 8 = h8, 57 = a1,
# 64 = h1, i.e. rank 8 down to rank 1 and file a through file h within each
# rank. Pieces are `P N B R Q K` (White), `p n b r q k` (Black) and `"."`
# for an empty square. The remaining fields mirror the last five 'FEN'
# fields: `turn` is `"w"` or `"b"`, `castling` is a string such as `"KQkq"`
# or `"-"`, `ep` is an en passant target square name or `NA_character_`, and
# `halfmove` / `fullmove` are the two clocks.

#' Construct a chess position object
#'
#' Low-level constructor for the `gm_position` S3 class. Trusted input, no
#' validation. Users should call [gm_position()] or [gm_read_fen()] instead.
#'
#' @param board A length-64 character vector of piece codes, rank 8 to rank 1,
#'   file a to h. Uppercase = white, lowercase = black, `"."` = empty.
#' @param turn Side to move: `"w"` or `"b"`.
#' @param castling Castling availability string, e.g. `"KQkq"` or `"-"`.
#' @param ep En passant target square (e.g. `"e3"`) or `NA_character_`.
#' @param halfmove Halfmove clock (integer).
#' @param fullmove Fullmove number (integer).
#' @return An S3 object of class `gm_position`.
#' @noRd
new_gm_position <- function(board, turn = "w", castling = "KQkq",
                            ep = NA_character_, halfmove = 0L, fullmove = 1L) {
  structure(
    list(
      board = board, turn = turn, castling = castling,
      ep = ep, halfmove = halfmove, fullmove = fullmove
    ),
    class = "gm_position"
  )
}

#' @noRd
validate_gm_position <- function(x, call = rlang::caller_env()) {
  if (length(x$board) != 64L) {
    cli::cli_abort("A {.cls gm_position} board must have 64 squares.", call = call)
  }
  if (anyNA(match(x$board, .GM_CHARS))) {
    bad <- setdiff(x$board, .GM_CHARS)
    cli::cli_abort(
      "Unknown piece code{?s} on the board: {.val {bad}}.",
      call = call
    )
  }
  if (!x$turn %in% c("w", "b")) {
    cli::cli_abort(
      "{.field turn} must be {.val w} or {.val b}, not {.val {x$turn}}.",
      call = call
    )
  }
  n_white <- sum(x$board == "K")
  n_black <- sum(x$board == "k")
  if (n_white != 1L || n_black != 1L) {
    cli::cli_abort(c(
      "A position must have exactly one king per side.",
      "x" = "Found {n_white} white king{?s} and {n_black} black king{?s}."
    ), call = call)
  }
  if (!is.na(x$ep) && !.GM_RANK_CHR[.GM_SQ_INDEX[[x$ep]]] %in% c("3", "6")) {
    cli::cli_abort(
      "The en passant square must be on rank 3 or rank 6, not {.val {x$ep}}.",
      call = call
    )
  }
  if (is.na(x$halfmove) || x$halfmove < 0L || is.na(x$fullmove) || x$fullmove < 1L) {
    cli::cli_abort(
      "The halfmove clock must be non-negative and the fullmove number at least 1.",
      call = call
    )
  }
  x$castling <- .gm_castling_string(
    .gm_prune_castling(.gm_castling_bits(x$castling), .gm_encode_board(x$board))
  )
  st <- .gm_state(x)
  st$turn <- if (st$turn == 1L) 2L else 1L
  if (.gm_in_check(st)) {
    cli::cli_abort(c(
      "The side that is not to move is in check.",
      "i" = "That position cannot arise in a legal game."
    ), call = call)
  }
  x
}

# Drop castling rights that no longer have a king and rook in place. Stale
# rights are common in hand-written FEN, and silently pruning them keeps the
# generator honest without rejecting otherwise usable positions.
#' @noRd
.gm_prune_castling <- function(bits, b) {
  if (bits == 0L) {
    return(0L)
  }
  if (b[.GM_E1] != 6L) bits <- bitwAnd(bits, bitwNot(3L))
  if (b[.GM_E8] != 12L) bits <- bitwAnd(bits, bitwNot(12L))
  if (b[.GM_H1] != 4L) bits <- bitwAnd(bits, bitwNot(1L))
  if (b[.GM_A1] != 4L) bits <- bitwAnd(bits, bitwNot(2L))
  if (b[.GM_H8] != 10L) bits <- bitwAnd(bits, bitwNot(4L))
  if (b[.GM_A8] != 10L) bits <- bitwAnd(bits, bitwNot(8L))
  bits
}

#' Create a chess position
#'
#' User-facing constructor. Defaults to the standard starting position.
#'
#' @param fen A 'FEN' string. If `NULL` (default), the standard starting
#'   position is used.
#' @param call The execution environment, for error reporting. Experts only.
#' @return A [gm_position] object.
#' @export
#' @family core
#' @examples
#' gm_position()
#'
#' # Any legal position can be supplied as 'FEN'
#' gm_position("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1")
gm_position <- function(fen = NULL, call = rlang::caller_env()) {
  if (is.null(fen)) {
    fen <- .GM_START_FEN
  }
  gm_read_fen(fen, call = call)
}

#' Test whether an object is a chess position
#'
#' @param x An object to test.
#' @return A logical scalar.
#' @export
#' @family core
#' @examples
#' is_gm_position(gm_position())
is_gm_position <- function(x) {
  inherits(x, "gm_position")
}

#' @export
print.gm_position <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_text(
    "{.cls gm_position} \u2014 {.field {if (x$turn == 'w') 'White' else 'Black'}} to move"
  )
  cli::cli_verbatim(.gm_format_board(x))
  cli::cli_text("FEN: {.val {gm_write_fen(x)}}")
  invisible(x)
}

# An 8x8 unicode rendering of the board, with file and rank labels.
#' @noRd
.gm_format_board <- function(x, flip = FALSE) {
  glyph <- .GM_GLYPH[.gm_encode_board(x$board) + 1L]
  rows <- lapply(1:8, function(r) glyph[(r - 1L) * 8L + 1:8])
  labels <- as.character(8:1)
  if (flip) {
    rows <- rev(lapply(rows, rev))
    labels <- rev(labels)
    files <- paste(rev(letters[1:8]), collapse = " ")
  } else {
    files <- paste(letters[1:8], collapse = " ")
  }
  c(
    paste0(labels, "  ", vapply(rows, paste, character(1L), collapse = " ")),
    paste0("   ", files)
  )
}

#' @importFrom ggplot2 autoplot
#' @export
autoplot.gm_position <- function(object, ...) {
  gm_plot_board(object, ...)
}
