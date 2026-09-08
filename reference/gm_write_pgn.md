# Write a game to 'PGN'

Write a game to 'PGN'

## Usage

``` r
gm_write_pgn(game, path = NULL, overwrite = FALSE)
```

## Arguments

- game:

  A [gm_game](https://r-heller.github.io/gambitR/reference/gm_game.md)
  object.

- path:

  Optional output path. If `NULL` (default), the 'PGN' string is
  returned invisibly instead of being written.

- overwrite:

  If `FALSE` (default), error rather than overwrite `path`.

## Value

The 'PGN' string, invisibly. Called for its side effect when `path` is
supplied.

## See also

Other io:
[`gm_read_fen()`](https://r-heller.github.io/gambitR/reference/gm_read_fen.md),
[`gm_read_pgn()`](https://r-heller.github.io/gambitR/reference/gm_read_pgn.md),
[`gm_write_fen()`](https://r-heller.github.io/gambitR/reference/gm_write_fen.md)

## Examples

``` r
cat(gm_write_pgn(gm_read_pgn("1. e4 e5 *", text = TRUE)))
#> [Event "gambitR game"]
#> [Site "?"]
#> [Date "????.??.??"]
#> [Round "?"]
#> [White "?"]
#> [Black "?"]
#> [Result "*"]
#> 
#> 1. e4 e5 *
```
