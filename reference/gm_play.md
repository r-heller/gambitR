# Play a full game between two strategies

Run a self-play game from a starting position until termination, with
each side driven by a strategy function.

## Usage

``` r
gm_play(
  white = "engine",
  black = "engine",
  position = NULL,
  max_moves = 200L,
  verbose = TRUE
)
```

## Arguments

- white, black:

  Strategy functions. Each takes a
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
  and returns a single move in standard algebraic notation. Defaults to
  the native engine at depth 2. Character shortcuts `"random"` and
  `"engine"` are also accepted.

- position:

  Starting
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md).
  Default is the standard start.

- max_moves:

  Maximum full moves before adjudication. Default `200`.

- verbose:

  If `TRUE` (default), report each move.

## Value

A [gm_game](https://r-heller.github.io/gambitR/reference/gm_game.md)
object.

## Details

A game ends on checkmate, stalemate, the fifty-move rule, threefold
repetition, insufficient mating material, or when `max_moves` full moves
have been played, in which case the game is adjudicated as a draw. The
termination reason is recorded in the game's `Termination` tag.

## See also

Other play:
[`gm_simulate()`](https://r-heller.github.io/gambitR/reference/gm_simulate.md)

## Examples

``` r
# \donttest{
gm_play(white = "random", black = "random", max_moves = 10, verbose = FALSE)
#> <gm_game> — 20 half-moves, result "1/2-1/2"
#> random vs random
#> 1. g3 d5 2. b4 Bf5 3. Na3 c5 4. Nc4 Qa5 5. Nd6+ Kd8 6. Nh3 Qb6 ...
# }
```
