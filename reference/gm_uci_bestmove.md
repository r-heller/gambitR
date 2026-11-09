# Query a 'UCI' engine for the best move

Optional deeper analysis backend. Requires the processx package and an
external 'UCI' engine binary (e.g. 'Stockfish') on the system. Falls
back with an informative error when either is unavailable.

## Usage

``` r
gm_uci_bestmove(
  position,
  engine_path = NULL,
  movetime = 1000L,
  verbose = TRUE,
  call = rlang::caller_env()
)
```

## Arguments

- position:

  A
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
  object.

- engine_path:

  Path to a 'UCI' engine binary. If `NULL` (default), `gambitR` looks on
  the `PATH` for `stockfish`.

- movetime:

  Search time in milliseconds. Default `1000`.

- verbose:

  If `TRUE` (default), report engine info lines.

- call:

  The execution environment, for error reporting. Experts only.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `san`, `score` and `pv` (principal variation string). One
row.

## Details

The engine is driven through the standard handshake: `uci` until
`uciok`, `isready` until `readyok`, then `position fen ...` and
`go movetime ...` until `bestmove`. Scores are reported from White's
perspective, matching
[`gm_evaluate()`](https://r-heller.github.io/gambitR/reference/gm_evaluate.md),
and a forced mate is reported as a score of `100000 - plies`. The engine
process is always shut down, including when the call errors.

## See also

Other analysis:
[`gm_bestmove()`](https://r-heller.github.io/gambitR/reference/gm_bestmove.md),
[`gm_evaluate()`](https://r-heller.github.io/gambitR/reference/gm_evaluate.md)

## Examples

``` r
if (FALSE) { # requireNamespace("processx", quietly = TRUE) && nzchar(Sys.which("stockfish"))
gm_uci_bestmove(gm_position())
}
```
