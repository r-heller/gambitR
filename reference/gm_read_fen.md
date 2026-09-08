# Read a position from 'FEN'

Parse a Forsyth-Edwards Notation string into a
[gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
object.

## Usage

``` r
gm_read_fen(fen, call = rlang::caller_env())
```

## Arguments

- fen:

  A single 'FEN' string.

- call:

  The execution environment, for error reporting. Experts only.

## Value

A
[gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
object.

## Details

All six 'FEN' fields are validated: the piece placement must describe
exactly 64 squares over eight ranks, the side to move must be `w` or
`b`, castling availability must be a subset of `KQkq`, the en passant
target must sit on rank 3 or rank 6, and both clocks must be
non-negative. The halfmove and fullmove fields may be omitted, in which
case they default to `0` and `1`. Castling rights that are not backed by
a king and rook on their home squares are dropped, so a stale flag
cannot produce an illegal castling move later.

## See also

Other io:
[`gm_read_pgn()`](https://r-heller.github.io/gambitR/reference/gm_read_pgn.md),
[`gm_write_fen()`](https://r-heller.github.io/gambitR/reference/gm_write_fen.md),
[`gm_write_pgn()`](https://r-heller.github.io/gambitR/reference/gm_write_pgn.md)

## Examples

``` r
gm_read_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
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
```
