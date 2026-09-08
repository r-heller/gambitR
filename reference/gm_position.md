# Create a chess position

User-facing constructor. Defaults to the standard starting position.

## Usage

``` r
gm_position(fen = NULL, call = rlang::caller_env())
```

## Arguments

- fen:

  A 'FEN' string. If `NULL` (default), the standard starting position is
  used.

- call:

  The execution environment, for error reporting. Experts only.

## Value

A gm_position object.

## See also

Other core:
[`gm_game`](https://r-heller.github.io/gambitR/reference/gm_game.md),
[`gm_legal_moves()`](https://r-heller.github.io/gambitR/reference/gm_legal_moves.md),
[`gm_move()`](https://r-heller.github.io/gambitR/reference/gm_move.md),
[`gm_status()`](https://r-heller.github.io/gambitR/reference/gm_status.md),
[`is_gm_game()`](https://r-heller.github.io/gambitR/reference/is_gm_game.md),
[`is_gm_position()`](https://r-heller.github.io/gambitR/reference/is_gm_position.md)

## Examples

``` r
gm_position()
#> <gm_position> — White to move
#> 8  ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜
#> 7  ♟ ♟ ♟ ♟ ♟ ♟ ♟ ♟
#> 6  · · · · · · · ·
#> 5  · · · · · · · ·
#> 4  · · · · · · · ·
#> 3  · · · · · · · ·
#> 2  ♙ ♙ ♙ ♙ ♙ ♙ ♙ ♙
#> 1  ♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖
#>    a b c d e f g h
#> FEN: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

# Any legal position can be supplied as 'FEN'
gm_position("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1")
#> <gm_position> — White to move
#> 8  · · · · · · · ·
#> 7  · · ♟ · · · · ·
#> 6  · · · ♟ · · · ·
#> 5  ♔ ♙ · · · · · ♜
#> 4  · ♖ · · · ♟ · ♚
#> 3  · · · · · · · ·
#> 2  · · · · ♙ · ♙ ·
#> 1  · · · · · · · ·
#>    a b c d e f g h
#> FEN: "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1"
```
