# Move generation.
#
# See tables.R for the board encoding. Moves are carried internally as a list
# of six parallel integer vectors:
#
#   from    origin square 1..64
#   to      target square 1..64
#   piece   moving piece code 1..12
#   capture captured piece code, 0 when the move is not a capture
#   flag    0 quiet, 1 capture, 2 castle, 3 en passant, 4 promotion
#   promo   promoted piece code, 0 when the move is not a promotion
#
# A promotion that also captures carries flag 4 and a non-zero `capture`.

.GM_FLAG_NAMES <- c("normal", "capture", "castle", "ep", "promo")

#' @noRd
.gm_empty_moves <- function() {
  list(
    from = integer(0L), to = integer(0L), piece = integer(0L),
    capture = integer(0L), flag = integer(0L), promo = integer(0L)
  )
}

# Is `sq` attacked by side `by` (1 White, 2 Black) on integer board `b`?
#' @noRd
.gm_attacked <- function(b, sq, by) {
  if (is.na(sq)) {
    return(FALSE)
  }
  if (by == 1L) {
    if (any(b[.GM_PAWN_ATT_B[[sq]]] == 1L)) return(TRUE)
    if (any(b[.GM_KNIGHT[[sq]]] == 2L)) return(TRUE)
    if (any(b[.GM_KING[[sq]]] == 6L)) return(TRUE)
    straight <- 4L
    diagonal <- 3L
    queen <- 5L
  } else {
    if (any(b[.GM_PAWN_ATT_W[[sq]]] == 7L)) return(TRUE)
    if (any(b[.GM_KNIGHT[[sq]]] == 8L)) return(TRUE)
    if (any(b[.GM_KING[[sq]]] == 12L)) return(TRUE)
    straight <- 10L
    diagonal <- 9L
    queen <- 11L
  }
  rays <- .GM_RAYS[[sq]]
  for (d in 1:8) {
    ray <- rays[[d]]
    if (!length(ray)) next
    v <- b[ray]
    occ <- v != 0L
    if (!any(occ)) next
    p <- v[which.max(occ)]
    if (p == queen) return(TRUE)
    if (d <= 4L) {
      if (p == straight) return(TRUE)
    } else if (p == diagonal) {
      return(TRUE)
    }
  }
  FALSE
}

# Apply a move to an integer board only; used both by `.gm_make()` and by the
# legality filter, which does not need the rest of the state.
#' @noRd
.gm_move_board <- function(b, from, to, piece, flag, promo) {
  b[to] <- if (flag == 4L) promo else piece
  b[from] <- 0L
  if (flag == 2L) {
    if (to == .GM_G1) {
      b[.GM_F1] <- 4L
      b[.GM_H1] <- 0L
    } else if (to == .GM_C1) {
      b[.GM_D1] <- 4L
      b[.GM_A1] <- 0L
    } else if (to == .GM_G8) {
      b[.GM_F8] <- 10L
      b[.GM_H8] <- 0L
    } else if (to == .GM_C8) {
      b[.GM_D8] <- 10L
      b[.GM_A8] <- 0L
    }
  } else if (flag == 3L) {
    if (piece == 1L) b[to + 8L] <- 0L else b[to - 8L] <- 0L
  }
  b
}

# Apply move `i` of `mv` to state `st`, returning the new state.
#' @noRd
.gm_make <- function(st, mv, i) {
  from <- mv$from[i]
  to <- mv$to[i]
  piece <- mv$piece[i]
  flag <- mv$flag[i]
  white <- st$turn == 1L
  cast <- st$castling
  if (cast != 0L) {
    if (piece == 6L) {
      cast <- bitwAnd(cast, bitwNot(3L))
    } else if (piece == 12L) {
      cast <- bitwAnd(cast, bitwNot(12L))
    }
    if (from == .GM_H1 || to == .GM_H1) cast <- bitwAnd(cast, bitwNot(1L))
    if (from == .GM_A1 || to == .GM_A1) cast <- bitwAnd(cast, bitwNot(2L))
    if (from == .GM_H8 || to == .GM_H8) cast <- bitwAnd(cast, bitwNot(4L))
    if (from == .GM_A8 || to == .GM_A8) cast <- bitwAnd(cast, bitwNot(8L))
  }
  ep <- 0L
  if (piece == 1L && from - to == 16L) {
    ep <- from - 8L
  } else if (piece == 7L && to - from == 16L) {
    ep <- from + 8L
  }
  pawn_move <- piece == 1L || piece == 7L
  list(
    b = .gm_move_board(st$b, from, to, piece, flag, mv$promo[i]),
    turn = if (white) 2L else 1L,
    castling = cast,
    ep = ep,
    halfmove = if (pawn_move || mv$capture[i] != 0L) 0L else st$halfmove + 1L,
    fullmove = if (white) st$fullmove else st$fullmove + 1L
  )
}

# Pseudo-legal generation: every move that respects the piece movement rules
# but may still leave the mover's own king in check. Castling is fully
# validated here (empty squares, king not in check and not passing through
# an attacked square).
#' @noRd
.gm_gen_pseudo <- function(st) {
  b <- st$b
  white <- st$turn == 1L
  ep <- st$ep
  size <- 256L
  m_from <- integer(size)
  m_to <- integer(size)
  m_piece <- integer(size)
  m_capt <- integer(size)
  m_flag <- integer(size)
  m_promo <- integer(size)
  n <- 0L
  if (white) {
    lo <- 1L
    hi <- 6L
    elo <- 7L
    ehi <- 12L
    off <- 0L
    promos <- c(5L, 4L, 3L, 2L)
    ep_victim <- 7L
  } else {
    lo <- 7L
    hi <- 12L
    elo <- 1L
    ehi <- 6L
    off <- 6L
    promos <- c(11L, 10L, 9L, 8L)
    ep_victim <- 1L
  }
  own <- which(b >= lo & b <= hi)
  for (from in own) {
    pc <- b[from]
    ptype <- pc - off
    if (ptype == 1L) {
      one <- if (white) from - 8L else from + 8L
      last_rank <- if (white) one <= 8L else one >= 57L
      if (b[one] == 0L) {
        if (last_rank) {
          for (pp in promos) {
            n <- n + 1L
            m_from[n] <- from
            m_to[n] <- one
            m_piece[n] <- pc
            m_capt[n] <- 0L
            m_flag[n] <- 4L
            m_promo[n] <- pp
          }
        } else {
          n <- n + 1L
          m_from[n] <- from
          m_to[n] <- one
          m_piece[n] <- pc
          m_capt[n] <- 0L
          m_flag[n] <- 0L
          m_promo[n] <- 0L
          on_start <- if (white) {
            from >= 49L && from <= 56L
          } else {
            from >= 9L && from <= 16L
          }
          if (on_start) {
            two <- if (white) from - 16L else from + 16L
            if (b[two] == 0L) {
              n <- n + 1L
              m_from[n] <- from
              m_to[n] <- two
              m_piece[n] <- pc
              m_capt[n] <- 0L
              m_flag[n] <- 0L
              m_promo[n] <- 0L
            }
          }
        }
      }
      targets <- if (white) .GM_PAWN_ATT_W[[from]] else .GM_PAWN_ATT_B[[from]]
      for (to in targets) {
        tgt <- b[to]
        if (tgt >= elo && tgt <= ehi) {
          if (if (white) to <= 8L else to >= 57L) {
            for (pp in promos) {
              n <- n + 1L
              m_from[n] <- from
              m_to[n] <- to
              m_piece[n] <- pc
              m_capt[n] <- tgt
              m_flag[n] <- 4L
              m_promo[n] <- pp
            }
          } else {
            n <- n + 1L
            m_from[n] <- from
            m_to[n] <- to
            m_piece[n] <- pc
            m_capt[n] <- tgt
            m_flag[n] <- 1L
            m_promo[n] <- 0L
          }
        } else if (tgt == 0L && ep != 0L && to == ep) {
          n <- n + 1L
          m_from[n] <- from
          m_to[n] <- to
          m_piece[n] <- pc
          m_capt[n] <- ep_victim
          m_flag[n] <- 3L
          m_promo[n] <- 0L
        }
      }
    } else if (ptype == 2L || ptype == 6L) {
      targets <- if (ptype == 2L) .GM_KNIGHT[[from]] else .GM_KING[[from]]
      for (to in targets) {
        tgt <- b[to]
        if (tgt >= lo && tgt <= hi) next
        n <- n + 1L
        m_from[n] <- from
        m_to[n] <- to
        m_piece[n] <- pc
        m_capt[n] <- tgt
        m_flag[n] <- if (tgt == 0L) 0L else 1L
        m_promo[n] <- 0L
      }
    } else {
      dset <- if (ptype == 3L) 5:8 else if (ptype == 4L) 1:4 else 1:8
      rays <- .GM_RAYS[[from]]
      for (d in dset) {
        for (to in rays[[d]]) {
          tgt <- b[to]
          if (tgt == 0L) {
            n <- n + 1L
            m_from[n] <- from
            m_to[n] <- to
            m_piece[n] <- pc
            m_capt[n] <- 0L
            m_flag[n] <- 0L
            m_promo[n] <- 0L
            next
          }
          if (tgt >= elo && tgt <= ehi) {
            n <- n + 1L
            m_from[n] <- from
            m_to[n] <- to
            m_piece[n] <- pc
            m_capt[n] <- tgt
            m_flag[n] <- 1L
            m_promo[n] <- 0L
          }
          break
        }
      }
    }
  }
  cast <- st$castling
  if (cast != 0L) {
    other <- if (white) 2L else 1L
    if (white) {
      king_sq <- .GM_E1
      kcode <- 6L
      rcode <- 4L
      short_bit <- 1L
      long_bit <- 2L
      short_empty <- c(.GM_F1, .GM_G1)
      long_empty <- c(.GM_D1, .GM_C1, .GM_B1)
      rook_short <- .GM_H1
      rook_long <- .GM_A1
      short_to <- .GM_G1
      long_to <- .GM_C1
      short_pass <- .GM_F1
      long_pass <- .GM_D1
    } else {
      king_sq <- .GM_E8
      kcode <- 12L
      rcode <- 10L
      short_bit <- 4L
      long_bit <- 8L
      short_empty <- c(.GM_F8, .GM_G8)
      long_empty <- c(.GM_D8, .GM_C8, .GM_B8)
      rook_short <- .GM_H8
      rook_long <- .GM_A8
      short_to <- .GM_G8
      long_to <- .GM_C8
      short_pass <- .GM_F8
      long_pass <- .GM_D8
    }
    if (b[king_sq] == kcode) {
      in_check <- NA
      if (bitwAnd(cast, short_bit) != 0L && b[rook_short] == rcode &&
        all(b[short_empty] == 0L)) {
        in_check <- .gm_attacked(b, king_sq, other)
        if (!in_check && !.gm_attacked(b, short_pass, other)) {
          n <- n + 1L
          m_from[n] <- king_sq
          m_to[n] <- short_to
          m_piece[n] <- kcode
          m_capt[n] <- 0L
          m_flag[n] <- 2L
          m_promo[n] <- 0L
        }
      }
      if (bitwAnd(cast, long_bit) != 0L && b[rook_long] == rcode &&
        all(b[long_empty] == 0L)) {
        if (is.na(in_check)) in_check <- .gm_attacked(b, king_sq, other)
        if (!in_check && !.gm_attacked(b, long_pass, other)) {
          n <- n + 1L
          m_from[n] <- king_sq
          m_to[n] <- long_to
          m_piece[n] <- kcode
          m_capt[n] <- 0L
          m_flag[n] <- 2L
          m_promo[n] <- 0L
        }
      }
    }
  }
  if (n == 0L) {
    return(.gm_empty_moves())
  }
  idx <- seq_len(n)
  list(
    from = m_from[idx], to = m_to[idx], piece = m_piece[idx],
    capture = m_capt[idx], flag = m_flag[idx], promo = m_promo[idx]
  )
}

# Pseudo-legal moves filtered to those that leave the mover's own king safe.
#' @noRd
.gm_gen_legal <- function(st) {
  mv <- .gm_gen_pseudo(st)
  n <- length(mv$from)
  if (n == 0L) {
    return(mv)
  }
  b <- st$b
  other <- if (st$turn == 1L) 2L else 1L
  kcode <- if (st$turn == 1L) 6L else 12L
  ksq <- which(b == kcode)[1L]
  from <- mv$from
  to <- mv$to
  piece <- mv$piece
  flag <- mv$flag
  promo <- mv$promo
  keep <- logical(n)
  for (i in seq_len(n)) {
    nb <- .gm_move_board(b, from[i], to[i], piece[i], flag[i], promo[i])
    keep[i] <- !.gm_attacked(nb, if (piece[i] == kcode) to[i] else ksq, other)
  }
  if (all(keep)) {
    return(mv)
  }
  lapply(mv, function(x) x[keep])
}

#' @noRd
.gm_in_check <- function(st) {
  other <- if (st$turn == 1L) 2L else 1L
  .gm_attacked(st$b, .gm_king_square(st$b, st$turn), other)
}

# Standard algebraic notation for every move in `mv`, with disambiguation
# resolved against the move list itself and check / mate suffixes.
#' @noRd
.gm_san_all <- function(st, mv) {
  n <- length(mv$from)
  if (n == 0L) {
    return(character(0L))
  }
  from <- mv$from
  to <- mv$to
  capt <- mv$capture
  flag <- mv$flag
  promo <- mv$promo
  ptype <- ((mv$piece - 1L) %% 6L) + 1L
  idx <- seq_len(n)
  san <- character(n)
  for (i in idx) {
    if (flag[i] == 2L) {
      s <- if (to[i] == .GM_G1 || to[i] == .GM_G8) "O-O" else "O-O-O"
    } else if (ptype[i] == 1L) {
      s <- if (capt[i] != 0L) {
        paste0(.GM_FILE_CHR[from[i]], "x", .GM_SQUARES[to[i]])
      } else {
        .GM_SQUARES[to[i]]
      }
      if (flag[i] == 4L) {
        s <- paste0(s, "=", .GM_PIECE_LETTER[((promo[i] - 1L) %% 6L) + 1L])
      }
    } else {
      rivals <- which(ptype == ptype[i] & to == to[i] & idx != i)
      dis <- ""
      if (length(rivals)) {
        rf <- from[rivals]
        if (!(.GM_COL[from[i]] %in% .GM_COL[rf])) {
          dis <- .GM_FILE_CHR[from[i]]
        } else if (!(.GM_ROW[from[i]] %in% .GM_ROW[rf])) {
          dis <- .GM_RANK_CHR[from[i]]
        } else {
          dis <- .GM_SQUARES[from[i]]
        }
      }
      s <- paste0(
        .GM_PIECE_LETTER[ptype[i]], dis,
        if (capt[i] != 0L) "x" else "", .GM_SQUARES[to[i]]
      )
    }
    st2 <- .gm_make(st, mv, i)
    if (.gm_attacked(st2$b, .gm_king_square(st2$b, st2$turn), st$turn)) {
      s <- paste0(s, if (length(.gm_gen_legal(st2)$from) == 0L) "#" else "+")
    }
    san[i] <- s
  }
  san
}

# Long algebraic notation, e.g. "e2e4" or "e7e8q".
#' @noRd
.gm_lan_all <- function(mv) {
  n <- length(mv$from)
  if (n == 0L) {
    return(character(0L))
  }
  suffix <- rep("", n)
  is_promo <- mv$flag == 4L
  if (any(is_promo)) {
    suffix[is_promo] <- tolower(
      .GM_PIECE_LETTER[((mv$promo[is_promo] - 1L) %% 6L) + 1L]
    )
  }
  paste0(.GM_SQUARES[mv$from], .GM_SQUARES[mv$to], suffix)
}

#' @noRd
.gm_moves_tibble <- function(st, mv, san = NULL) {
  n <- length(mv$from)
  if (n == 0L) {
    return(tibble::tibble(
      from = character(0L), to = character(0L), piece = character(0L),
      san = character(0L), promotion = character(0L), flag = character(0L)
    ))
  }
  promotion <- rep(NA_character_, n)
  is_promo <- mv$flag == 4L
  if (any(is_promo)) {
    promotion[is_promo] <- .GM_PIECE_LETTER[((mv$promo[is_promo] - 1L) %% 6L) + 1L]
  }
  tibble::tibble(
    from = .GM_SQUARES[mv$from],
    to = .GM_SQUARES[mv$to],
    piece = .GM_CHARS[mv$piece + 1L],
    san = san %||% .gm_san_all(st, mv),
    promotion = promotion,
    flag = .GM_FLAG_NAMES[mv$flag + 1L]
  )
}

#' Generate legal moves
#'
#' Enumerate every legal move in a position, accounting for checks, pins,
#' castling, en passant and promotion.
#'
#' @param position A [gm_position] object.
#' @return A [tibble::tibble()] with one row per legal move and columns:
#'   `from` (character square, e.g. `"e2"`), `to` (character square),
#'   `piece` (character), `san` (character, standard algebraic notation),
#'   `promotion` (character or `NA`), `flag` (character: `"normal"`,
#'   `"capture"`, `"castle"`, `"ep"`, `"promo"`). Zero rows in checkmate or
#'   stalemate.
#' @export
#' @family core
#' @examples
#' gm_legal_moves(gm_position())
gm_legal_moves <- function(position) {
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.")
  }
  st <- .gm_state(position)
  .gm_moves_tibble(st, .gm_gen_legal(st))
}

# Normalise user move input so that "0-0", "Nf3!?" and "e2-e4" all resolve.
#' @noRd
.gm_normalise_move <- function(move) {
  key <- trimws(move)
  key <- sub("\\s*e\\.p\\.$", "", key)
  key <- sub("[!?]+$", "", key)
  if (grepl("^[0oO]-[0oO](-[0oO])?[+#]?$", key)) {
    key <- gsub("[0o]", "O", key)
  }
  key
}

#' Apply a move to a position
#'
#' @param position A [gm_position] object.
#' @param move A single move in standard algebraic notation (e.g. `"Nf3"`) or
#'   long algebraic (e.g. `"g1f3"`).
#' @param call The execution environment, for error reporting. Experts only.
#' @return A new [gm_position] object with the move applied.
#' @export
#' @family core
#' @examples
#' gm_move(gm_position(), "e4")
gm_move <- function(position, move, call = rlang::caller_env()) {
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.", call = call)
  }
  if (!is.character(move) || length(move) != 1L || is.na(move)) {
    cli::cli_abort("{.arg move} must be a single non-NA string.", call = call)
  }
  st <- .gm_state(position)
  mv <- .gm_gen_legal(st)
  if (length(mv$from) == 0L) {
    status <- .gm_status_state(st)
    cli::cli_abort(c(
      "There are no legal moves in this position.",
      "i" = "The position is {.val {status}}."
    ), call = call)
  }
  san <- .gm_san_all(st, mv)
  key <- .gm_normalise_move(move)
  i <- match(key, san)
  if (is.na(i)) i <- match(key, gsub("[+#]", "", san))
  if (is.na(i)) i <- match(tolower(gsub("-", "", key, fixed = TRUE)), .gm_lan_all(mv))
  if (is.na(i)) {
    cli::cli_abort(c(
      "{.val {move}} is not a legal move in this position.",
      "i" = "Legal moves are {.val {sort(san)}}."
    ), call = call)
  }
  .gm_unstate(.gm_make(st, mv, i))
}

#' Position status
#'
#' Report whether the side to move is in check, checkmate or stalemate.
#'
#' @param position A [gm_position] object.
#' @return A length-1 character string: one of `"normal"`, `"check"`,
#'   `"checkmate"`, `"stalemate"`.
#' @export
#' @family core
#' @examples
#' gm_status(gm_position())
gm_status <- function(position) {
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.")
  }
  .gm_status_state(.gm_state(position))
}

#' @noRd
.gm_status_state <- function(st) {
  check <- .gm_in_check(st)
  has_move <- length(.gm_gen_legal(st)$from) > 0L
  if (!has_move) {
    if (check) "checkmate" else "stalemate"
  } else if (check) {
    "check"
  } else {
    "normal"
  }
}
