# Plot an evaluation curve

Visualise how the evaluation changes across the moves of a game. The
area between the curve and the axis is filled towards whichever side is
ahead, split exactly at the ply where the advantage changes hands.

## Usage

``` r
gm_plot_eval(game, depth = 1L)
```

## Arguments

- game:

  A [gm_game](https://r-heller.github.io/gambitR/reference/gm_game.md)
  object.

- depth:

  Search depth for per-move evaluation. Default `1` (static).

## Value

A `ggplot2` object with move number on x and centipawn score on y.

## Details

With `depth = 1` each position is scored by
[`gm_evaluate()`](https://r-heller.github.io/gambitR/reference/gm_evaluate.md).
A larger `depth` re-scores every position with
[`gm_bestmove()`](https://r-heller.github.io/gambitR/reference/gm_bestmove.md),
which is far slower but accounts for tactics. Forced mates are clamped
for display so a single mate score cannot flatten the rest of the curve.

## See also

Other visualization:
[`gm_plot_board()`](https://r-heller.github.io/gambitR/reference/gm_plot_board.md)

## Examples

``` r
# \donttest{
gm_plot_eval(gm_read_pgn("1. e4 e5 2. Nf3 Nc6 *", text = TRUE))

# }
```
