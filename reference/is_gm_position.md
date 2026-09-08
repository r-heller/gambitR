# Test whether an object is a chess position

Test whether an object is a chess position

## Usage

``` r
is_gm_position(x)
```

## Arguments

- x:

  An object to test.

## Value

A logical scalar.

## See also

Other core:
[`gm_game`](https://r-heller.github.io/gambitR/reference/gm_game.md),
[`gm_legal_moves()`](https://r-heller.github.io/gambitR/reference/gm_legal_moves.md),
[`gm_move()`](https://r-heller.github.io/gambitR/reference/gm_move.md),
[`gm_position()`](https://r-heller.github.io/gambitR/reference/gm_position.md),
[`gm_status()`](https://r-heller.github.io/gambitR/reference/gm_status.md),
[`is_gm_game()`](https://r-heller.github.io/gambitR/reference/is_gm_game.md)

## Examples

``` r
is_gm_position(gm_position())
#> [1] TRUE
```
