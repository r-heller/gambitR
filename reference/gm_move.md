# Apply a move to a position

Apply a move to a position

## Usage

``` r
gm_move(position, move, call = rlang::caller_env())
```

## Arguments

- position:

  A
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
  object.

- move:

  A single move in standard algebraic notation (e.g. `"Nf3"`) or long
  algebraic (e.g. `"g1f3"`).

- call:

  The execution environment, for error reporting. Experts only.

## Value

A new
[gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
object with the move applied.

## See also

Other core:
[`gm_game`](https://r-heller.github.io/gambitR/reference/gm_game.md),
[`gm_legal_moves()`](https://r-heller.github.io/gambitR/reference/gm_legal_moves.md),
[`gm_position()`](https://r-heller.github.io/gambitR/reference/gm_position.md),
[`gm_status()`](https://r-heller.github.io/gambitR/reference/gm_status.md),
[`is_gm_game()`](https://r-heller.github.io/gambitR/reference/is_gm_game.md),
[`is_gm_position()`](https://r-heller.github.io/gambitR/reference/is_gm_position.md)

## Examples

``` r
gm_move(gm_position(), "e4")
#> <gm_position> — Black to move
#> 8  ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜
#> 7  ♟ ♟ ♟ ♟ ♟ ♟ ♟ ♟
#> 6  · · · · · · · ·
#> 5  · · · · · · · ·
#> 4  · · · · ♙ · · ·
#> 3  · · · · · · · ·
#> 2  ♙ ♙ ♙ ♙ · ♙ ♙ ♙
#> 1  ♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖
#>    a b c d e f g h
#> FEN: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
```
