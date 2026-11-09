# gambitR 0.2.0

## CRAN preparation

* The 'UCI' example now runs only when 'processx' and a `stockfish` binary are
  available, without calling unexported functions.
* `gm_run_app()` example is wrapped in `if (interactive())` instead of
  `\dontrun{}`.
* Package help page uses the vector logo, which is now shipped in the source
  package; the build no longer leaves an empty `tools/` directory behind.
* Repetition identity ignores an en-passant target when no legal en-passant
  capture exists (FIDE 9.2.3); the 'UCI' backend of `gm_bestmove()` forwards
  `depth`; non-finite and fractional counts are rejected before any work starts;
  seeded puzzles restore the caller's random number generator state.
* README links to the maintenance record by absolute URL.

# gambitR 0.1.0

## Initial release

### Core
* `gm_position()`, `gm_read_fen()`, `gm_write_fen()`: position construction and FEN I/O.
* `gm_legal_moves()`, `gm_move()`, `gm_status()`: legal move generation and game state.
* `gm_read_pgn()`, `gm_write_pgn()`: PGN parsing and serialisation.
* Move generation is verified against the published perft reference counts for
  the start position, Kiwipete and positions 3 to 5, so castling rights, en
  passant, pins and promotion are exact.

### Analysis
* `gm_evaluate()`: static heuristic evaluation.
* `gm_bestmove()`: native alpha-beta search, with an optional UCI backend.
* `gm_uci_bestmove()`: optional external engine hook (e.g. Stockfish).

### Play & simulation
* `gm_play()`: full game between two strategies, terminating on checkmate,
  stalemate, the fifty-move rule, threefold repetition, insufficient material
  or the move limit.
* `gm_simulate()`: batch tournament simulation.

### Openings & puzzles
* `gm_openings()`, `gm_identify_opening()`: ECO opening explorer over a
  bundled book of 180 lines.
* `gm_puzzle()`, `gm_check_solution()`: tactical puzzle trainer over a bundled
  set of 16 positions.

### Visualization & app
* `gm_plot_board()`, `gm_plot_eval()`: ggplot2 board and evaluation plots. The
  pieces are drawn as vector shapes rather than as text, so a board scales with
  the figure and renders on every device, including pdf and postscript.
* `gm_run_app()`: interactive Shiny study application (Play, Analyse, Simulate, Openings, Puzzles, Study).
