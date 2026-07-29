# gambitR <img src="man/figures/logo.png" align="right" height="139" alt="gambitR logo" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/r-heller/gambitR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-heller/gambitR/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/r-heller/gambitR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/r-heller/gambitR?branch=main)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

A self-contained chess toolkit in native R: legal move generation, FEN/PGN I/O,
position evaluation and alpha-beta search, batch simulation, an opening
explorer, a puzzle trainer, and an interactive Shiny study app. An optional UCI
hook (e.g. Stockfish) enables deeper analysis.

## Why gambitR?

Several R chess packages already exist, each with a different focus. `gambitR`
is the only one that combines native (dependency-free) move generation with
play, simulation, an opening explorer, a puzzle trainer, and a full interactive
study app in one package.

| Feature | gambitR | chess | rchess | chess2plyrs |
|---|:--:|:--:|:--:|:--:|
| Native R move generation (no wrapper) | ✅ | ❌ (python-chess) | ❌ (chess.js) | ✅ |
| FEN / PGN read & write | ✅ | ✅ | ✅ | ✅ (FEN) |
| Legality / check / mate detection | ✅ | ✅ | ✅ | ✅ |
| Built-in engine (search) | ✅ minimax + α-β | ❌ | ❌ | ✅ minimax |
| Optional UCI / Stockfish hook | ✅ | ❌ | ❌ | ❌ |
| Batch strategy simulation | ✅ | ❌ | ❌ | ❌ |
| Opening explorer (ECO) | ✅ | ❌ | ❌ | ❌ |
| Puzzle trainer | ✅ | ❌ | ❌ | ❌ |
| ggplot2 board & eval plots | ✅ | partial | ✅ | ✅ (base) |
| Interactive Shiny study app | ✅ (6 tabs) | ❌ | ❌ | ❌ |
| No system/JS runtime required | ✅ | ❌ (Python) | ❌ (JS) | ✅ |

If you mainly want to parse and explore existing PGNs as trees, `chess` is
excellent and purpose-built for that. `gambitR` targets play, analysis,
simulation and study in a single native-R package.

Move generation, PGN parsing and the UCI client are implemented from the public
FEN/PGN/UCI specifications and perft references — not ported from any existing
(GPL) codebase.

## Installation

```r
# install.packages("remotes")
remotes::install_github("r-heller/gambitR")
```

## Quick start

```r
library(gambitR)

pos <- gm_position()
gm_legal_moves(pos)
gm_plot_board(pos)

# Play the native engine against a random mover
gm_play(white = "engine", black = "random")

# Launch the interactive app
gm_run_app()
```
