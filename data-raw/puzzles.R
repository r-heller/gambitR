# Build inst/extdata/puzzles.rds.
#
# Every puzzle below is composed here rather than imported from an external
# collection. Each one is verified against this package's own generator
# before it is written out: the position must be legal, every move of the
# solution must be legal in turn, and any line ending in "#" must really end
# in checkmate. Run with
#
#   devtools::load_all(".")
#   source("data-raw/puzzles.R")

puzzle <- function(id, fen, solution, theme, rating) {
  list(id = id, fen = fen, solution = solution, theme = theme, rating = as.integer(rating))
}

raw <- list(
  puzzle(
    "gm-0001", "6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1",
    "Ra8#", "backRank", 800
  ),
  puzzle(
    "gm-0002", "6k1/5ppp/8/8/8/8/5PPP/3Q2K1 w - - 0 1",
    "Qd8#", "backRank", 850
  ),
  puzzle(
    "gm-0003", "1r4k1/5ppp/8/8/8/8/5PPP/6K1 b - - 0 1",
    "Rb1#", "backRank", 850
  ),
  puzzle(
    "gm-0004", "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4",
    "Qxf7#", "mateIn1", 700
  ),
  puzzle(
    "gm-0005", "6rk/6pp/8/6N1/8/8/8/6K1 w - - 0 1",
    "Nf7#", "mateIn1", 1000
  ),
  puzzle(
    "gm-0006", "7k/8/6K1/8/8/8/8/1Q6 w - - 0 1",
    "Qb8#", "mateIn1", 900
  ),
  puzzle(
    "gm-0007", "rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq g3 0 2",
    "Qh4#", "mateIn1", 600
  ),
  puzzle(
    "gm-0008", "3r3k/6pp/8/6N1/8/8/8/6K1 w - - 0 1",
    c("Nf7+", "Kg8", "Nxd8"), "fork", 1200
  ),
  puzzle(
    "gm-0009", "7r/6k1/8/8/8/4B3/8/1K6 w - - 0 1",
    "Bd4+", "skewer", 1100
  ),
  puzzle(
    "gm-0010", "4k3/8/8/3q4/4P3/8/8/4K3 w - - 0 1",
    "exd5", "hangingPiece", 700
  ),
  puzzle(
    "gm-0011", "8/4P3/8/8/8/8/8/k6K w - - 0 1",
    "e8=Q", "promotion", 700
  ),
  puzzle(
    "gm-0012", "8/1P6/8/8/8/6k1/8/6K1 w - - 0 1",
    "b8=Q+", "promotion", 750
  ),
  puzzle(
    "gm-0013", "6k1/5ppp/8/8/8/8/5PPP/2R3K1 w - - 0 1",
    "Rc8#", "backRank", 800
  ),
  puzzle(
    "gm-0014", "7k/8/5K2/8/8/8/1Q6/8 w - - 0 1",
    c("Qg2", "Kh7", "Qg7#"), "mateIn2", 1300
  ),
  puzzle(
    "gm-0015", "4k3/4q3/8/8/8/8/4R3/4K3 w - - 0 1",
    "Rxe7+", "pin", 900
  ),
  puzzle(
    "gm-0016", "4k3/8/8/4q3/3P4/8/8/7K b - - 0 1",
    "Qxd4", "hangingPiece", 750
  )
)

# Verification -----------------------------------------------------------
for (p in raw) {
  position <- gambitR::gm_position(p$fen)
  for (san in p$solution) {
    legal <- gambitR::gm_legal_moves(position)$san
    if (!san %in% legal) {
      stop(sprintf(
        "%s: '%s' is not legal. Legal moves: %s",
        p$id, san, paste(legal, collapse = " ")
      ), call. = FALSE)
    }
    position <- gambitR::gm_move(position, san)
  }
  last <- p$solution[[length(p$solution)]]
  if (grepl("#$", last) && gambitR::gm_status(position) != "checkmate") {
    stop(sprintf("%s: '%s' claims mate but is not", p$id, last), call. = FALSE)
  }
  if (grepl("^mateIn", p$theme) && !grepl("#$", last)) {
    stop(sprintf("%s: a mating theme must end in mate", p$id), call. = FALSE)
  }
  # Forced replies only: the opponent must have exactly one answer.
  replay <- gambitR::gm_position(p$fen)
  for (k in seq_along(p$solution)) {
    if (k %% 2L == 0L && nrow(gambitR::gm_legal_moves(replay)) != 1L) {
      stop(sprintf("%s: reply %d is not forced", p$id, k), call. = FALSE)
    }
    replay <- gambitR::gm_move(replay, p$solution[[k]])
  }
}

puzzles <- tibble::tibble(
  id = vapply(raw, function(p) p$id, character(1L)),
  fen = vapply(raw, function(p) p$fen, character(1L)),
  solution = lapply(raw, function(p) p$solution),
  theme = vapply(raw, function(p) p$theme, character(1L)),
  rating = vapply(raw, function(p) p$rating, integer(1L))
)

stopifnot(!anyDuplicated(puzzles$id), nrow(puzzles) > 0L)

dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
saveRDS(puzzles, "inst/extdata/puzzles.rds", version = 3, compress = "xz")

message(sprintf(
  "Wrote %d puzzles (%s) to inst/extdata/puzzles.rds [%s]",
  nrow(puzzles), paste(sort(unique(puzzles$theme)), collapse = ", "),
  format(structure(file.size("inst/extdata/puzzles.rds"), class = "object_size"),
    units = "auto"
  )
))
