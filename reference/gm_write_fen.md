# Write a position to 'FEN'

The exact inverse of
[`gm_read_fen()`](https://r-heller.github.io/gambitR/reference/gm_read_fen.md):
reading the output of this function reproduces the position it was
given.

## Usage

``` r
gm_write_fen(x, ...)
```

## Arguments

- x:

  A
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
  object.

- ...:

  Unused; must be empty.

## Value

A length-1 character 'FEN' string.

## See also

Other io:
[`gm_read_fen()`](https://r-heller.github.io/gambitR/reference/gm_read_fen.md),
[`gm_read_pgn()`](https://r-heller.github.io/gambitR/reference/gm_read_pgn.md),
[`gm_write_pgn()`](https://r-heller.github.io/gambitR/reference/gm_write_pgn.md)

## Examples

``` r
gm_write_fen(gm_position())
#> [1] "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
```
