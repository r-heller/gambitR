# Static evaluation.
#
# Piece-square tables are derived here from a handful of positional rules
# rather than transcribed from an existing engine: a centralisation term, a
# pawn advancement term and a king shelter term. Building them from formulas
# keeps the table authorship self-contained and makes the intent legible.

.GM_PIECE_VALUE <- c(100, 320, 330, 500, 900, 0)

# A 64 x 6 matrix of positional bonuses in centipawns, indexed by square (in
# the package's a8-first ordering) and piece type P N B R Q K, always from
# White's point of view. Black squares are mirrored through `.GM_MIRROR`.
.GM_PST <- local({
  row <- rep(1:8, each = 8L)
  col <- rep(1:8, times = 8L)
  back <- row == 8L
  advance <- 8L - row
  centre <- 3.5 - pmax(abs(col - 4.5), abs(row - 4.5))
  centre_file <- 3.5 - abs(col - 4.5)

  pawn <- 1.5 * advance^2 +
    12 * centre * (advance >= 2L & advance <= 4L) -
    15 * (advance == 1L & col %in% 4:5) +
    6 * (advance == 1L & col %in% c(1:3, 6:8))
  pawn[advance == 0L | advance == 7L] <- 0

  knight <- -52 + 18 * centre - 8 * back + 6 * (advance >= 3L & advance <= 4L)

  bishop <- -18 + 7 * centre - 6 * back +
    10 * (advance == 1L & col %in% c(2L, 7L))

  rook <- 2 * centre_file + 20 * (advance == 6L) +
    5 * (back & col %in% 4:5)

  queen <- -16 + 5 * centre - 4 * back

  king <- -14 * centre - 8 * advance +
    24 * (advance == 0L & col %in% c(2L, 3L, 7L)) +
    10 * (advance == 0L & col == 8L)

  out <- cbind(pawn, knight, bishop, rook, queen, king)
  dimnames(out) <- NULL
  round(out)
})

#' Evaluate a position
#'
#' Static heuristic evaluation from White's perspective: material balance plus
#' piece-square tables, mobility and simple king-safety terms. Positive favours
#' White, negative favours Black, in centipawns.
#'
#' The score is the weighted sum of three terms. `material` scales the piece
#' values (pawn 100, knight 320, bishop 330, rook 500, queen 900) together
#' with the piece-square bonuses; `mobility` scales the difference in the
#' number of legal moves available to each side; and `king_safety` scales the
#' difference in pawn shelter in front of each king. The function is
#' colour-symmetric: mirroring a position negates its score.
#'
#' @param position A [gm_position] object.
#' @param weights A named list of term weights with any of the elements
#'   `material`, `mobility` and `king_safety`. If `NULL` (default), package
#'   defaults are used.
#' @return A length-1 numeric score in centipawns.
#' @export
#' @family analysis
#' @examples
#' gm_evaluate(gm_position())
#'
#' # A queen up for White
#' gm_evaluate(gm_position("rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"))
gm_evaluate <- function(position, weights = NULL) {
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.")
  }
  .gm_eval_state(.gm_state(position), .gm_merge_weights(weights))
}

#' @noRd
.gm_default_weights <- function() {
  list(material = 1, mobility = 4, king_safety = 8)
}

#' @noRd
.gm_merge_weights <- function(weights, call = rlang::caller_env()) {
  defaults <- .gm_default_weights()
  if (is.null(weights)) {
    return(defaults)
  }
  if (!is.list(weights) || is.null(names(weights)) || anyNA(names(weights))) {
    cli::cli_abort("{.arg weights} must be a named list or {.code NULL}.", call = call)
  }
  unknown <- setdiff(names(weights), names(defaults))
  if (length(unknown)) {
    cli::cli_abort(c(
      "Unknown weight{?s} {.val {unknown}}.",
      "i" = "Known weights are {.val {names(defaults)}}."
    ), call = call)
  }
  utils::modifyList(defaults, weights)
}

#' @noRd
.gm_eval_state <- function(st, w = .gm_default_weights()) {
  b <- st$b
  occupied <- which(b > 0L)
  code <- b[occupied]
  is_white <- code <= 6L
  ptype <- ((code - 1L) %% 6L) + 1L
  sign <- ifelse(is_white, 1, -1)
  square <- ifelse(is_white, occupied, .GM_MIRROR[occupied])
  material <- sum(sign * .GM_PIECE_VALUE[ptype])
  placement <- sum(sign * .GM_PST[cbind(square, ptype)])
  mobility <- .gm_mobility(st)
  shelter <- .gm_king_shelter(b)
  w$material * (material + placement) +
    w$mobility * (mobility[[1L]] - mobility[[2L]]) +
    w$king_safety * (shelter[[1L]] - shelter[[2L]])
}

# Legal move counts for both sides. The en passant right belongs to the side
# to move only, and moves that would capture a king (possible only when the
# other side is already in check) are excluded.
#' @noRd
.gm_mobility <- function(st) {
  count <- function(side) {
    probe <- st
    probe$turn <- side
    if (side != st$turn) probe$ep <- 0L
    captures <- .gm_gen_legal(probe)$capture
    sum(captures != 6L & captures != 12L)
  }
  c(count(1L), count(2L))
}

# Pawn shelter: own pawns on the three files around the king, one rank ahead
# counting fully and two ranks ahead counting half.
#' @noRd
.gm_king_shelter <- function(b) {
  shelter <- function(king_code, pawn_code, white) {
    king <- which(b == king_code)[1L]
    if (is.na(king)) {
      return(0)
    }
    r <- .GM_ROW[king]
    f <- .GM_COL[king]
    total <- 0
    for (step in 1:2) {
      rr <- if (white) r - step else r + step
      if (rr < 1L || rr > 8L) next
      for (ff in max(1L, f - 1L):min(8L, f + 1L)) {
        if (b[(rr - 1L) * 8L + ff] == pawn_code) {
          total <- total + if (step == 1L) 1 else 0.5
        }
      }
    }
    total
  }
  c(shelter(6L, 1L, TRUE), shelter(12L, 7L, FALSE))
}

# Vertically mirror a position and swap colours; used to check that the
# evaluation is colour-symmetric.
#' @noRd
.gm_mirror_position <- function(position) {
  b <- .gm_encode_board(position$board)
  mirrored <- integer(64L)
  mirrored[.GM_MIRROR] <- b
  swapped <- ifelse(mirrored == 0L, 0L, ((mirrored + 5L) %% 12L) + 1L)
  bits <- .gm_castling_bits(position$castling)
  flipped <- bitwOr(
    bitwShiftL(bitwAnd(bits, 3L), 2L),
    bitwShiftR(bitwAnd(bits, 12L), 2L)
  )
  ep <- position$ep
  if (!is.na(ep)) ep <- .GM_SQUARES[.GM_MIRROR[.GM_SQ_INDEX[[ep]]]]
  new_gm_position(
    board = .gm_decode_board(swapped),
    turn = if (position$turn == "w") "b" else "w",
    castling = .gm_castling_string(flipped),
    ep = ep,
    halfmove = position$halfmove,
    fullmove = position$fullmove
  )
}
