# Build inst/extdata/eco.rds.
#
# The book is written out by hand here rather than imported from an existing
# project: ECO codes and opening names are reference designations, and every
# move sequence below is replayed through this package's own generator, which
# both validates the line and produces the resulting FEN. Run with
#
#   devtools::load_all(".")
#   source("data-raw/eco.R")

lines <- c(
  # A: flank openings and irregular queen's pawn
  "A00|Anderssen's Opening|a3",
  "A00|Ware Opening|a4",
  "A00|Saragossa Opening|c3",
  "A00|Mieses Opening|d3",
  "A00|Van 't Kruijs Opening|e3",
  "A00|Barnes Opening|f3",
  "A00|Hungarian Opening|g3",
  "A00|Clemenz Opening|h3",
  "A00|Amar Opening|Nh3",
  "A00|Polish Opening|b4",
  "A00|Grob Opening|g4",
  "A01|Nimzo-Larsen Attack|b3",
  "A02|Bird's Opening|f4",
  "A03|Bird's Opening, Dutch Variation|f4 d5",
  "A04|Reti Opening|Nf3",
  "A05|Reti Opening, King's Indian Attack|Nf3 Nf6",
  "A06|Reti Opening, Nimzo-Larsen Attack|Nf3 d5",
  "A07|King's Indian Attack|Nf3 d5 g3",
  "A08|King's Indian Attack, Sicilian Variation|Nf3 d5 g3 c5 Bg2",
  "A09|Reti Opening, Advance Variation|Nf3 d5 c4",
  "A10|English Opening|c4",
  "A11|English Opening, Caro-Kann Defensive System|c4 c6",
  "A13|English Opening, Agincourt Defense|c4 e6",
  "A15|English Opening, Anglo-Indian Defense|c4 Nf6",
  "A16|English Opening, Anglo-Indian, Queen's Knight|c4 Nf6 Nc3",
  "A18|English Opening, Mikenas-Carls Variation|c4 Nf6 Nc3 e6 e4",
  "A20|English Opening, King's English Variation|c4 e5",
  "A21|English Opening, King's English, Reversed Sicilian|c4 e5 Nc3",
  "A22|English Opening, King's English, Two Knights|c4 e5 Nc3 Nf6",
  "A25|English Opening, King's English, Reversed Closed Sicilian|c4 e5 Nc3 Nc6",
  "A26|English Opening, King's English, Botvinnik System|c4 e5 Nc3 Nc6 g3 g6 Bg2 Bg7 d3 d6",
  "A28|English Opening, Four Knights System|c4 e5 Nc3 Nf6 Nf3 Nc6",
  "A29|English Opening, Four Knights, Kingside Fianchetto|c4 e5 Nc3 Nf6 Nf3 Nc6 g3",
  "A30|English Opening, Symmetrical Variation|c4 c5",
  "A34|English Opening, Symmetrical, Three Knights|c4 c5 Nc3",
  "A35|English Opening, Symmetrical, Four Knights|c4 c5 Nc3 Nc6",
  "A40|Queen's Pawn Game|d4",
  "A40|Englund Gambit|d4 e5",
  "A41|Queen's Pawn Game, Modern Defense|d4 d6",
  "A42|Modern Defense, Averbakh System|d4 d6 c4 g6 Nc3 Bg7 e4",
  "A43|Old Benoni Defense|d4 c5",
  "A45|Indian Game|d4 Nf6",
  "A45|Trompowsky Attack|d4 Nf6 Bg5",
  "A46|Indian Game, Knights Variation|d4 Nf6 Nf3",
  "A48|East Indian Defense|d4 Nf6 Nf3 g6",
  "A50|Indian Game, Normal Variation|d4 Nf6 c4",
  "A51|Budapest Gambit|d4 Nf6 c4 e5",
  "A53|Old Indian Defense|d4 Nf6 c4 d6",
  "A56|Benoni Defense|d4 Nf6 c4 c5",
  "A57|Benko Gambit|d4 Nf6 c4 c5 d5 b5",
  "A60|Benoni Defense, Modern Variation|d4 Nf6 c4 c5 d5 e6",
  "A80|Dutch Defense|d4 f5",
  "A82|Dutch Defense, Staunton Gambit|d4 f5 e4",
  "A84|Dutch Defense, Classical Variation|d4 f5 c4",
  "A85|Dutch Defense, Queen's Knight Variation|d4 f5 c4 Nf6 Nc3",
  "A87|Dutch Defense, Leningrad Variation|d4 f5 c4 Nf6 g3 g6 Bg2 Bg7 Nf3",
  "A90|Dutch Defense, Stonewall Variation|d4 f5 c4 Nf6 g3 e6 Bg2",

  # B: semi-open defenses other than the French
  "B00|King's Pawn Opening|e4",
  "B00|Nimzowitsch Defense|e4 Nc6",
  "B00|Owen Defense|e4 b6",
  "B01|Scandinavian Defense|e4 d5",
  "B01|Scandinavian Defense, Main Line|e4 d5 exd5 Qxd5 Nc3 Qa5",
  "B02|Alekhine Defense|e4 Nf6",
  "B03|Alekhine Defense, Exchange Variation|e4 Nf6 e5 Nd5 d4 d6 c4 Nb6 exd6",
  "B04|Alekhine Defense, Modern Variation|e4 Nf6 e5 Nd5 d4 d6 Nf3",
  "B06|Modern Defense|e4 g6",
  "B07|Pirc Defense|e4 d6 d4 Nf6 Nc3",
  "B09|Pirc Defense, Austrian Attack|e4 d6 d4 Nf6 Nc3 g6 f4",
  "B10|Caro-Kann Defense|e4 c6",
  "B12|Caro-Kann Defense, Advance Variation|e4 c6 d4 d5 e5",
  "B13|Caro-Kann Defense, Exchange Variation|e4 c6 d4 d5 exd5 cxd5",
  "B15|Caro-Kann Defense, Main Line|e4 c6 d4 d5 Nc3",
  "B18|Caro-Kann Defense, Classical Variation|e4 c6 d4 d5 Nc3 dxe4 Nxe4 Bf5",
  "B20|Sicilian Defense|e4 c5",
  "B21|Sicilian Defense, Smith-Morra Gambit|e4 c5 d4",
  "B22|Sicilian Defense, Alapin Variation|e4 c5 c3",
  "B23|Sicilian Defense, Closed Variation|e4 c5 Nc3",
  "B27|Sicilian Defense, Hyperaccelerated Dragon|e4 c5 Nf3 g6",
  "B29|Sicilian Defense, Nimzo-American Variation|e4 c5 Nf3 Nf6",
  "B30|Sicilian Defense, Old Sicilian|e4 c5 Nf3 Nc6",
  "B31|Sicilian Defense, Rossolimo Variation|e4 c5 Nf3 Nc6 Bb5",
  "B32|Sicilian Defense, Lowenthal Variation|e4 c5 Nf3 Nc6 d4 cxd4 Nxd4 e5",
  "B33|Sicilian Defense, Sveshnikov Variation|e4 c5 Nf3 Nc6 d4 cxd4 Nxd4 Nf6 Nc3 e5",
  "B34|Sicilian Defense, Accelerated Dragon|e4 c5 Nf3 Nc6 d4 cxd4 Nxd4 g6",
  "B40|Sicilian Defense, French Variation|e4 c5 Nf3 e6",
  "B41|Sicilian Defense, Kan Variation|e4 c5 Nf3 e6 d4 cxd4 Nxd4 a6",
  "B44|Sicilian Defense, Taimanov Variation|e4 c5 Nf3 e6 d4 cxd4 Nxd4 Nc6",
  "B50|Sicilian Defense, Modern Variations|e4 c5 Nf3 d6",
  "B51|Sicilian Defense, Moscow Variation|e4 c5 Nf3 d6 Bb5+",
  "B54|Sicilian Defense, Modern Variations, Main Line|e4 c5 Nf3 d6 d4 cxd4 Nxd4",
  "B70|Sicilian Defense, Dragon Variation|e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 g6",
  "B76|Sicilian Defense, Dragon, Yugoslav Attack|e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 g6 Be3 Bg7 f3 O-O Qd2 Nc6",
  "B80|Sicilian Defense, Scheveningen Variation|e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 e6",
  "B90|Sicilian Defense, Najdorf Variation|e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 a6",
  "B92|Sicilian Defense, Najdorf, Opocensky Variation|e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 a6 Be2",

  # C: French Defense and 1. e4 e5
  "C00|French Defense|e4 e6",
  "C01|French Defense, Exchange Variation|e4 e6 d4 d5 exd5 exd5",
  "C02|French Defense, Advance Variation|e4 e6 d4 d5 e5",
  "C03|French Defense, Tarrasch Variation|e4 e6 d4 d5 Nd2",
  "C10|French Defense, Paulsen Variation|e4 e6 d4 d5 Nc3",
  "C11|French Defense, Classical Variation|e4 e6 d4 d5 Nc3 Nf6",
  "C15|French Defense, Winawer Variation|e4 e6 d4 d5 Nc3 Bb4",
  "C20|King's Pawn Game|e4 e5",
  "C21|Center Game|e4 e5 d4",
  "C23|Bishop's Opening|e4 e5 Bc4",
  "C25|Vienna Game|e4 e5 Nc3",
  "C30|King's Gambit|e4 e5 f4",
  "C33|King's Gambit Accepted|e4 e5 f4 exf4",
  "C34|King's Gambit Accepted, King's Knight Gambit|e4 e5 f4 exf4 Nf3",
  "C40|King's Knight Opening|e4 e5 Nf3",
  "C41|Philidor Defense|e4 e5 Nf3 d6",
  "C42|Petrov Defense|e4 e5 Nf3 Nf6",
  "C44|King's Pawn Game, Normal Variation|e4 e5 Nf3 Nc6",
  "C44|Ponziani Opening|e4 e5 Nf3 Nc6 c3",
  "C45|Scotch Game|e4 e5 Nf3 Nc6 d4 exd4 Nxd4",
  "C46|Three Knights Opening|e4 e5 Nf3 Nc6 Nc3",
  "C47|Four Knights Game, Scotch Variation|e4 e5 Nf3 Nc6 Nc3 Nf6 d4",
  "C48|Four Knights Game, Spanish Variation|e4 e5 Nf3 Nc6 Nc3 Nf6 Bb5",
  "C50|Italian Game|e4 e5 Nf3 Nc6 Bc4",
  "C50|Italian Game, Giuoco Piano|e4 e5 Nf3 Nc6 Bc4 Bc5",
  "C51|Evans Gambit|e4 e5 Nf3 Nc6 Bc4 Bc5 b4",
  "C53|Italian Game, Classical Variation|e4 e5 Nf3 Nc6 Bc4 Bc5 c3",
  "C55|Italian Game, Two Knights Defense|e4 e5 Nf3 Nc6 Bc4 Nf6",
  "C57|Italian Game, Two Knights, Fried Liver Attack|e4 e5 Nf3 Nc6 Bc4 Nf6 Ng5 d5 exd5 Nxd5 Nxf7",
  "C60|Ruy Lopez|e4 e5 Nf3 Nc6 Bb5",
  "C62|Ruy Lopez, Old Steinitz Defense|e4 e5 Nf3 Nc6 Bb5 d6",
  "C64|Ruy Lopez, Classical Variation|e4 e5 Nf3 Nc6 Bb5 Bc5",
  "C65|Ruy Lopez, Berlin Defense|e4 e5 Nf3 Nc6 Bb5 Nf6",
  "C68|Ruy Lopez, Exchange Variation|e4 e5 Nf3 Nc6 Bb5 a6 Bxc6",
  "C70|Ruy Lopez, Morphy Defense|e4 e5 Nf3 Nc6 Bb5 a6 Ba4",
  "C77|Ruy Lopez, Morphy Defense, Anderssen Variation|e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 d3",
  "C84|Ruy Lopez, Closed Variation|e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7",
  "C88|Ruy Lopez, Closed, Anti-Marshall|e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7 Re1 b5 Bb3 O-O a4",
  "C89|Ruy Lopez, Marshall Attack|e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O Be7 Re1 b5 Bb3 O-O c3 d5",

  # D: closed and semi-closed queen's pawn
  "D00|Queen's Pawn Game|d4 d5",
  "D01|Richter-Veresov Attack|d4 d5 Nc3 Nf6 Bg5",
  "D02|Queen's Pawn Game, London System|d4 d5 Nf3 Nf6 Bf4",
  "D03|Torre Attack|d4 d5 Nf3 Nf6 Bg5",
  "D04|Colle System|d4 d5 Nf3 Nf6 e3",
  "D06|Queen's Gambit|d4 d5 c4",
  "D07|Queen's Gambit Declined, Chigorin Defense|d4 d5 c4 Nc6",
  "D08|Queen's Gambit Declined, Albin Countergambit|d4 d5 c4 e5",
  "D10|Slav Defense|d4 d5 c4 c6",
  "D11|Slav Defense, Modern Line|d4 d5 c4 c6 Nf3",
  "D15|Slav Defense, Three Knights Variation|d4 d5 c4 c6 Nf3 Nf6 Nc3",
  "D16|Slav Defense, Alapin Variation|d4 d5 c4 c6 Nf3 Nf6 Nc3 dxc4",
  "D20|Queen's Gambit Accepted|d4 d5 c4 dxc4",
  "D30|Queen's Gambit Declined|d4 d5 c4 e6",
  "D31|Queen's Gambit Declined, Semi-Slav|d4 d5 c4 e6 Nc3",
  "D32|Queen's Gambit Declined, Tarrasch Defense|d4 d5 c4 e6 Nc3 c5",
  "D35|Queen's Gambit Declined, Exchange Variation|d4 d5 c4 e6 Nc3 Nf6 cxd5 exd5",
  "D37|Queen's Gambit Declined, Three Knights Variation|d4 d5 c4 e6 Nc3 Nf6 Nf3",
  "D43|Semi-Slav Defense|d4 d5 c4 e6 Nc3 Nf6 Nf3 c6",
  "D44|Semi-Slav Defense, Botvinnik Variation|d4 d5 c4 e6 Nc3 Nf6 Nf3 c6 Bg5 dxc4",
  "D45|Semi-Slav Defense, Accelerated Meran|d4 d5 c4 e6 Nc3 Nf6 Nf3 c6 e3",
  "D50|Queen's Gambit Declined, Modern Variation|d4 d5 c4 e6 Nc3 Nf6 Bg5",
  "D51|Queen's Gambit Declined, Cambridge Springs Defense|d4 d5 c4 e6 Nc3 Nf6 Bg5 Nbd7",
  "D53|Queen's Gambit Declined, Lasker Defense|d4 d5 c4 e6 Nc3 Nf6 Bg5 Be7",
  "D80|Grunfeld Defense|d4 Nf6 c4 g6 Nc3 d5",
  "D85|Grunfeld Defense, Exchange Variation|d4 Nf6 c4 g6 Nc3 d5 cxd5 Nxd5 e4 Nxc3 bxc3",
  "D90|Grunfeld Defense, Three Knights Variation|d4 Nf6 c4 g6 Nc3 d5 Nf3",

  # E: Indian defenses
  "E00|Indian Game, East Indian Defense|d4 Nf6 c4 e6",
  "E01|Catalan Opening, Closed Variation|d4 Nf6 c4 e6 g3 d5 Bg2",
  "E04|Catalan Opening, Open Defense|d4 Nf6 c4 e6 g3 d5 Bg2 dxc4 Nf3",
  "E10|Indian Game, Anti-Nimzo-Indian|d4 Nf6 c4 e6 Nf3",
  "E11|Bogo-Indian Defense|d4 Nf6 c4 e6 Nf3 Bb4+",
  "E12|Queen's Indian Defense|d4 Nf6 c4 e6 Nf3 b6",
  "E15|Queen's Indian Defense, Fianchetto Variation|d4 Nf6 c4 e6 Nf3 b6 g3",
  "E20|Nimzo-Indian Defense|d4 Nf6 c4 e6 Nc3 Bb4",
  "E21|Nimzo-Indian Defense, Three Knights Variation|d4 Nf6 c4 e6 Nc3 Bb4 Nf3",
  "E32|Nimzo-Indian Defense, Classical Variation|d4 Nf6 c4 e6 Nc3 Bb4 Qc2",
  "E40|Nimzo-Indian Defense, Rubinstein Variation|d4 Nf6 c4 e6 Nc3 Bb4 e3",
  "E60|King's Indian Defense|d4 Nf6 c4 g6",
  "E61|King's Indian Defense, Normal Variation|d4 Nf6 c4 g6 Nc3",
  "E62|King's Indian Defense, Fianchetto Variation|d4 Nf6 c4 g6 Nc3 Bg7 Nf3 d6 g3",
  "E70|King's Indian Defense, Normal Variation, King's Knight|d4 Nf6 c4 g6 Nc3 Bg7 e4",
  "E73|King's Indian Defense, Averbakh Variation|d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 Be2 O-O Bg5",
  "E80|King's Indian Defense, Samisch Variation|d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 f3",
  "E90|King's Indian Defense, Classical Variation|d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 Nf3",
  "E97|King's Indian Defense, Mar del Plata|d4 Nf6 c4 g6 Nc3 Bg7 e4 d6 Nf3 O-O Be2 e5 O-O Nc6 d5 Ne7"
)

parts <- do.call(rbind, strsplit(lines, "|", fixed = TRUE))
stopifnot(ncol(parts) == 3L)

eco <- tibble::tibble(
  eco = trimws(parts[, 1L]),
  name = trimws(parts[, 2L]),
  moves = trimws(parts[, 3L]),
  fen = NA_character_
)

stopifnot(!anyDuplicated(paste(eco$eco, eco$name)))
stopifnot(all(grepl("^[A-E][0-9]{2}$", eco$eco)))

# Replay every line so that a typo cannot reach the shipped book, and record
# the resulting position.
for (i in seq_len(nrow(eco))) {
  position <- gambitR::gm_position()
  tokens <- strsplit(eco$moves[[i]], " ", fixed = TRUE)[[1L]]
  for (san in tokens) {
    position <- tryCatch(
      gambitR::gm_move(position, san),
      error = function(e) {
        stop(sprintf(
          "%s %s: cannot play '%s' (%s)", eco$eco[[i]], eco$name[[i]], san,
          conditionMessage(e)
        ), call. = FALSE)
      }
    )
  }
  # Store the canonical SAN so book lookups compare like with like.
  eco$moves[[i]] <- paste(tokens, collapse = " ")
  eco$fen[[i]] <- gambitR::gm_write_fen(position)
}

eco <- eco[order(eco$eco, eco$name), ]

dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
saveRDS(eco, "inst/extdata/eco.rds", version = 3, compress = "xz")

message(sprintf(
  "Wrote %d openings (%s) to inst/extdata/eco.rds [%s]",
  nrow(eco), paste(range(eco$eco), collapse = "-"),
  format(structure(file.size("inst/extdata/eco.rds"), class = "object_size"),
    units = "auto"
  )
))
