# Changelog

## gambitR 0.1.0

### Initial release

#### Core

- [`gm_position()`](https://r-heller.github.io/gambitR/reference/gm_position.md),
  [`gm_read_fen()`](https://r-heller.github.io/gambitR/reference/gm_read_fen.md),
  [`gm_write_fen()`](https://r-heller.github.io/gambitR/reference/gm_write_fen.md):
  position construction and FEN I/O.
- [`gm_legal_moves()`](https://r-heller.github.io/gambitR/reference/gm_legal_moves.md),
  [`gm_move()`](https://r-heller.github.io/gambitR/reference/gm_move.md),
  [`gm_status()`](https://r-heller.github.io/gambitR/reference/gm_status.md):
  legal move generation and game state.
- [`gm_read_pgn()`](https://r-heller.github.io/gambitR/reference/gm_read_pgn.md),
  [`gm_write_pgn()`](https://r-heller.github.io/gambitR/reference/gm_write_pgn.md):
  PGN parsing and serialisation.
- Move generation is verified against the published perft reference
  counts for the start position, Kiwipete and positions 3 to 5, so
  castling rights, en passant, pins and promotion are exact.

#### Analysis

- [`gm_evaluate()`](https://r-heller.github.io/gambitR/reference/gm_evaluate.md):
  static heuristic evaluation.
- [`gm_bestmove()`](https://r-heller.github.io/gambitR/reference/gm_bestmove.md):
  native alpha-beta search, with an optional UCI backend.
- [`gm_uci_bestmove()`](https://r-heller.github.io/gambitR/reference/gm_uci_bestmove.md):
  optional external engine hook (e.g. Stockfish).

#### Play & simulation

- [`gm_play()`](https://r-heller.github.io/gambitR/reference/gm_play.md):
  full game between two strategies, terminating on checkmate, stalemate,
  the fifty-move rule, threefold repetition, insufficient material or
  the move limit.
- [`gm_simulate()`](https://r-heller.github.io/gambitR/reference/gm_simulate.md):
  batch tournament simulation.

#### Openings & puzzles

- [`gm_openings()`](https://r-heller.github.io/gambitR/reference/gm_openings.md),
  [`gm_identify_opening()`](https://r-heller.github.io/gambitR/reference/gm_identify_opening.md):
  ECO opening explorer over a bundled book of 180 lines.
- [`gm_puzzle()`](https://r-heller.github.io/gambitR/reference/gm_puzzle.md),
  [`gm_check_solution()`](https://r-heller.github.io/gambitR/reference/gm_check_solution.md):
  tactical puzzle trainer over a bundled set of 16 positions.

#### Visualization & app

- [`gm_plot_board()`](https://r-heller.github.io/gambitR/reference/gm_plot_board.md),
  [`gm_plot_eval()`](https://r-heller.github.io/gambitR/reference/gm_plot_eval.md):
  ggplot2 board and evaluation plots. The pieces are drawn as vector
  shapes rather than as text, so a board scales with the figure and
  renders on every device, including pdf and postscript.
- [`gm_run_app()`](https://r-heller.github.io/gambitR/reference/gm_run_app.md):
  interactive Shiny study application (Play, Analyse, Simulate,
  Openings, Puzzles, Study).
