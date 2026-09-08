# Position status

Report whether the side to move is in check, checkmate or stalemate.

## Usage

``` r
gm_status(position)
```

## Arguments

- position:

  A
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
  object.

## Value

A length-1 character string: one of `"normal"`, `"check"`,
`"checkmate"`, `"stalemate"`.

## See also

Other core:
[`gm_game`](https://r-heller.github.io/gambitR/reference/gm_game.md),
[`gm_legal_moves()`](https://r-heller.github.io/gambitR/reference/gm_legal_moves.md),
[`gm_move()`](https://r-heller.github.io/gambitR/reference/gm_move.md),
[`gm_position()`](https://r-heller.github.io/gambitR/reference/gm_position.md),
[`is_gm_game()`](https://r-heller.github.io/gambitR/reference/is_gm_game.md),
[`is_gm_position()`](https://r-heller.github.io/gambitR/reference/is_gm_position.md)

## Examples

``` r
gm_status(gm_position())
#> [1] "normal"
```
