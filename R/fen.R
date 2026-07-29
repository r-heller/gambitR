.GM_START_FEN <- "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

#' Read a position from 'FEN'
#'
#' Parse a Forsyth-Edwards Notation string into a [gm_position] object.
#'
#' All six 'FEN' fields are validated: the piece placement must describe
#' exactly 64 squares over eight ranks, the side to move must be `w` or `b`,
#' castling availability must be a subset of `KQkq`, the en passant target
#' must sit on rank 3 or rank 6, and both clocks must be non-negative. The
#' halfmove and fullmove fields may be omitted, in which case they default to
#' `0` and `1`. Castling rights that are not backed by a king and rook on
#' their home squares are dropped, so a stale flag cannot produce an illegal
#' castling move later.
#'
#' @param fen A single 'FEN' string.
#' @param call The execution environment, for error reporting. Experts only.
#' @return A [gm_position] object.
#' @export
#' @family io
#' @examples
#' gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
gm_read_fen <- function(fen, call = rlang::caller_env()) {
  if (!is.character(fen) || length(fen) != 1L || is.na(fen)) {
    cli::cli_abort("{.arg fen} must be a single non-NA string.", call = call)
  }
  fields <- strsplit(trimws(fen), "[[:space:]]+")[[1L]]
  fields <- fields[nzchar(fields)]
  if (length(fields) < 4L || length(fields) > 6L) {
    cli::cli_abort(c(
      "{.arg fen} must have between four and six space-separated fields.",
      "x" = "{.val {fen}} has {length(fields)}."
    ), call = call)
  }
  board <- .gm_parse_placement(fields[1L], call = call)
  turn <- fields[2L]
  if (!turn %in% c("w", "b")) {
    cli::cli_abort(c(
      "The side to move must be {.val w} or {.val b}.",
      "x" = "Got {.val {turn}}."
    ), call = call)
  }
  castling <- fields[3L]
  if (!identical(castling, "-")) {
    chars <- strsplit(castling, "", fixed = TRUE)[[1L]]
    bad <- setdiff(chars, names(.GM_CASTLE_BITS))
    if (!nzchar(castling) || length(bad) > 0L || anyDuplicated(chars) > 0L) {
      cli::cli_abort(c(
        "Castling availability must be {.val -} or a subset of {.val KQkq}.",
        "x" = "Got {.val {castling}}."
      ), call = call)
    }
  }
  ep_field <- fields[4L]
  if (identical(ep_field, "-")) {
    ep <- NA_character_
  } else if (grepl("^[a-h][36]$", ep_field)) {
    ep <- ep_field
  } else {
    cli::cli_abort(c(
      "The en passant target must be {.val -} or a square on rank 3 or 6.",
      "x" = "Got {.val {ep_field}}."
    ), call = call)
  }
  halfmove <- .gm_parse_clock(if (length(fields) >= 5L) fields[5L] else "0",
    field = "halfmove clock", min = 0L, call = call
  )
  fullmove <- .gm_parse_clock(if (length(fields) >= 6L) fields[6L] else "1",
    field = "fullmove number", min = 1L, call = call
  )
  validate_gm_position(
    new_gm_position(board, turn, castling, ep, halfmove, fullmove),
    call = call
  )
}

#' @noRd
.gm_parse_placement <- function(placement, call = rlang::caller_env()) {
  ranks <- strsplit(placement, "/", fixed = TRUE)[[1L]]
  if (length(ranks) != 8L) {
    cli::cli_abort(c(
      "The piece placement field must have eight ranks separated by {.val /}.",
      "x" = "{.val {placement}} has {length(ranks)}."
    ), call = call)
  }
  board <- character(0L)
  for (r in seq_len(8L)) {
    tokens <- strsplit(ranks[[r]], "", fixed = TRUE)[[1L]]
    row <- character(0L)
    for (tok in tokens) {
      if (grepl("^[1-8]$", tok)) {
        row <- c(row, rep(".", as.integer(tok)))
      } else if (tok %in% .GM_CHARS[-1L]) {
        row <- c(row, tok)
      } else {
        cli::cli_abort(c(
          "Unknown character {.val {tok}} in the piece placement field.",
          "i" = "Expected a digit 1-8 or one of {.val {.GM_CHARS[-1L]}}."
        ), call = call)
      }
    }
    if (length(row) != 8L) {
      cli::cli_abort(c(
        "Every rank of the piece placement field must describe eight squares.",
        "x" = "Rank {9L - r} ({.val {ranks[[r]]}}) describes {length(row)}."
      ), call = call)
    }
    board <- c(board, row)
  }
  board
}

#' @noRd
.gm_parse_clock <- function(x, field, min, call = rlang::caller_env()) {
  if (!grepl("^[0-9]+$", x)) {
    cli::cli_abort(c(
      "The {field} must be a non-negative whole number.",
      "x" = "Got {.val {x}}."
    ), call = call)
  }
  value <- as.integer(x)
  if (value < min) {
    cli::cli_abort(
      "The {field} must be at least {min}, not {value}.",
      call = call
    )
  }
  value
}

#' Write a position to 'FEN'
#'
#' The exact inverse of [gm_read_fen()]: reading the output of this function
#' reproduces the position it was given.
#'
#' @param x A [gm_position] object.
#' @param ... Unused; must be empty.
#' @return A length-1 character 'FEN' string.
#' @export
#' @family io
#' @examples
#' gm_write_fen(gm_position())
gm_write_fen <- function(x, ...) {
  rlang::check_dots_empty()
  if (!is_gm_position(x)) {
    cli::cli_abort("{.arg x} must be a {.cls gm_position} object.")
  }
  ranks <- vapply(1:8, function(r) {
    row <- x$board[(r - 1L) * 8L + 1:8]
    out <- character(0L)
    empty <- 0L
    for (sq in row) {
      if (identical(sq, ".")) {
        empty <- empty + 1L
      } else {
        if (empty > 0L) {
          out <- c(out, as.character(empty))
          empty <- 0L
        }
        out <- c(out, sq)
      }
    }
    if (empty > 0L) out <- c(out, as.character(empty))
    paste(out, collapse = "")
  }, character(1L))
  paste(
    paste(ranks, collapse = "/"),
    x$turn,
    if (is.na(x$castling) || !nzchar(x$castling)) "-" else x$castling,
    if (is.na(x$ep)) "-" else x$ep,
    as.integer(x$halfmove),
    as.integer(x$fullmove)
  )
}
