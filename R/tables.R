# Internal geometry, encoding and lookup tables.
#
# Board encoding (the single source of truth for the whole package):
#
#   Squares are integers 1..64. Index 1 is a8, index 8 is h8, index 57 is a1
#   and index 64 is h1, i.e. rank 8 down to rank 1 and, within each rank,
#   file a through file h. For index `i` the row is `(i - 1) %/% 8 + 1`
#   (row 1 is rank 8) and the column is `(i - 1) %% 8 + 1` (column 1 is
#   file a).
#
#   A `gm_position` stores the board as a length-64 *character* vector using
#   `P N B R Q K` for White, `p n b r q k` for Black and `"."` for an empty
#   square. Internally the move generator works on the equivalent *integer*
#   encoding: 0 is empty, 1..6 are the white pieces P N B R Q K and 7..12
#   their black counterparts. `.gm_encode_board()` and `.gm_decode_board()`
#   convert between the two.

.GM_CHARS <- c(".", "P", "N", "B", "R", "Q", "K", "p", "n", "b", "r", "q", "k")

.GM_PIECE_LETTER <- c("P", "N", "B", "R", "Q", "K")

.GM_GLYPH <- c(
  "\u00b7",
  "\u2659", "\u2658", "\u2657", "\u2656", "\u2655", "\u2654",
  "\u265f", "\u265e", "\u265d", "\u265c", "\u265b", "\u265a"
)

.GM_SQUARES <- paste0(rep(letters[1:8], times = 8L), rep(8:1, each = 8L))

.GM_SQ_INDEX <- local({
  x <- seq_len(64L)
  names(x) <- .GM_SQUARES
  x
})

# Row 1 is rank 8; column 1 is file a.
.GM_ROW <- rep(1:8, each = 8L)
.GM_COL <- rep(1:8, times = 8L)

# Vertical reflection of the board: the square a white piece sees as `i` is
# the square a black piece sees as `.GM_MIRROR[i]`. Used to evaluate both
# sides against a single set of piece-square tables.
.GM_MIRROR <- (8L - .GM_ROW) * 8L + .GM_COL
.GM_RANK_CHR <- rep(as.character(8:1), each = 8L)
.GM_FILE_CHR <- rep(letters[1:8], times = 8L)

# Castling availability is carried as a 4-bit mask in FEN order.
.GM_CASTLE_BITS <- c(K = 1L, Q = 2L, k = 4L, q = 8L)

# Named squares used by the castling rules.
.GM_A1 <- 57L
.GM_B1 <- 58L
.GM_C1 <- 59L
.GM_D1 <- 60L
.GM_E1 <- 61L
.GM_F1 <- 62L
.GM_G1 <- 63L
.GM_H1 <- 64L
.GM_A8 <- 1L
.GM_B8 <- 2L
.GM_C8 <- 3L
.GM_D8 <- 4L
.GM_E8 <- 5L
.GM_F8 <- 6L
.GM_G8 <- 7L
.GM_H8 <- 8L

# Ray directions 1..4 are the rook directions (up, down, left, right) and
# 5..8 the bishop directions. Each ray lists the squares outward from the
# origin in order, so a scan can stop at the first occupied square.
.GM_GEOM <- local({
  on_board <- function(r, f) r >= 1L && r <= 8L && f >= 1L && f <= 8L
  sq <- function(r, f) (r - 1L) * 8L + f
  dirs <- list(
    c(-1L, 0L), c(1L, 0L), c(0L, -1L), c(0L, 1L),
    c(-1L, -1L), c(-1L, 1L), c(1L, -1L), c(1L, 1L)
  )
  jumps <- list(
    c(-2L, -1L), c(-2L, 1L), c(-1L, -2L), c(-1L, 2L),
    c(1L, -2L), c(1L, 2L), c(2L, -1L), c(2L, 1L)
  )
  step_set <- function(r, f, offsets) {
    out <- vapply(offsets, function(m) {
      if (on_board(r + m[1L], f + m[2L])) sq(r + m[1L], f + m[2L]) else NA_integer_
    }, integer(1L))
    out[!is.na(out)]
  }
  rays <- vector("list", 64L)
  knight <- vector("list", 64L)
  king <- vector("list", 64L)
  pawn_w <- vector("list", 64L)
  pawn_b <- vector("list", 64L)
  for (i in seq_len(64L)) {
    r <- (i - 1L) %/% 8L + 1L
    f <- (i - 1L) %% 8L + 1L
    rl <- vector("list", 8L)
    for (d in seq_along(dirs)) {
      out <- integer(0L)
      rr <- r
      ff <- f
      repeat {
        rr <- rr + dirs[[d]][1L]
        ff <- ff + dirs[[d]][2L]
        if (!on_board(rr, ff)) break
        out <- c(out, sq(rr, ff))
      }
      rl[[d]] <- out
    }
    rays[[i]] <- rl
    knight[[i]] <- step_set(r, f, jumps)
    king[[i]] <- step_set(r, f, dirs)
    pawn_w[[i]] <- step_set(r, f, list(c(-1L, -1L), c(-1L, 1L)))
    pawn_b[[i]] <- step_set(r, f, list(c(1L, -1L), c(1L, 1L)))
  }
  list(
    rays = rays, knight = knight, king = king,
    pawn_w = pawn_w, pawn_b = pawn_b
  )
})

.GM_RAYS <- .GM_GEOM$rays
.GM_KNIGHT <- .GM_GEOM$knight
.GM_KING <- .GM_GEOM$king
.GM_PAWN_ATT_W <- .GM_GEOM$pawn_w
.GM_PAWN_ATT_B <- .GM_GEOM$pawn_b

#' @noRd
.gm_encode_board <- function(board) {
  match(board, .GM_CHARS) - 1L
}

#' @noRd
.gm_decode_board <- function(b) {
  .GM_CHARS[b + 1L]
}

#' @noRd
.gm_castling_bits <- function(x) {
  if (length(x) != 1L || is.na(x) || identical(x, "-") || !nzchar(x)) {
    return(0L)
  }
  ch <- strsplit(x, "", fixed = TRUE)[[1L]]
  as.integer(sum(.GM_CASTLE_BITS[ch], na.rm = TRUE))
}

#' @noRd
.gm_castling_string <- function(bits) {
  if (bits == 0L) {
    return("-")
  }
  paste(names(.GM_CASTLE_BITS)[bitwAnd(bits, .GM_CASTLE_BITS) > 0L], collapse = "")
}

# Convert a `gm_position` to the compact internal state used by the
# generator: integer board, integer side to move (1 White, 2 Black),
# castling mask, en passant square (0 when none) and the two clocks.
#' @noRd
.gm_state <- function(position) {
  ep <- position$ep
  list(
    b = .gm_encode_board(position$board),
    turn = if (identical(position$turn, "w")) 1L else 2L,
    castling = .gm_castling_bits(position$castling),
    ep = if (is.null(ep) || is.na(ep)) 0L else unname(.GM_SQ_INDEX[[ep]]),
    halfmove = as.integer(position$halfmove),
    fullmove = as.integer(position$fullmove)
  )
}

#' @noRd
.gm_unstate <- function(st) {
  new_gm_position(
    board = .gm_decode_board(st$b),
    turn = if (st$turn == 1L) "w" else "b",
    castling = .gm_castling_string(st$castling),
    ep = if (st$ep == 0L) NA_character_ else .GM_SQUARES[st$ep],
    halfmove = st$halfmove,
    fullmove = st$fullmove
  )
}

#' @noRd
.gm_king_square <- function(b, side) {
  which(b == if (side == 1L) 6L else 12L)[1L]
}
