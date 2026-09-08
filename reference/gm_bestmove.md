# Search for the best move

Minimax search with alpha-beta pruning to a fixed depth, driven by
[`gm_evaluate()`](https://r-heller.github.io/gambitR/reference/gm_evaluate.md).
This is the native R engine used for play and simulation.

## Usage

``` r
gm_bestmove(
  position,
  depth = 3L,
  engine = c("native", "uci"),
  verbose = TRUE,
  call = rlang::caller_env()
)
```

## Arguments

- position:

  A
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
  object.

- depth:

  Search depth in plies. Default `3`.

- engine:

  Backend: `"native"` (default, pure R minimax) or `"uci"` to delegate
  to an external 'UCI' engine via
  [`gm_uci_bestmove()`](https://r-heller.github.io/gambitR/reference/gm_uci_bestmove.md).

- verbose:

  If `TRUE` (default), report search progress.

- call:

  The execution environment, for error reporting. Experts only.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `san` (best move), `score` (centipawns, White's
perspective), `depth` (integer) and `nodes` (integer, nodes searched).
One row.

## Details

Moves are ordered captures first, most valuable victim before least
valuable attacker, which is what makes the alpha-beta cut-offs pay.
Forced mates are scored near `100000` and discounted by the distance to
mate, so a mate in one is preferred to a mate in three.

## See also

Other analysis:
[`gm_evaluate()`](https://r-heller.github.io/gambitR/reference/gm_evaluate.md),
[`gm_uci_bestmove()`](https://r-heller.github.io/gambitR/reference/gm_uci_bestmove.md)

## Examples

``` r
# \donttest{
gm_bestmove(gm_position(), depth = 2)
#> # A tibble: 1 × 4
#>   san   score depth nodes
#>   <chr> <dbl> <int> <int>
#> 1 e4        0     2   223
# }
```
