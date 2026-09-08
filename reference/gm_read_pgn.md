# Read a game from 'PGN'

Parse Portable Game Notation into a game object: header tags plus the
sequence of moves and resulting positions.

## Usage

``` r
gm_read_pgn(file, text = FALSE, call = rlang::caller_env())
```

## Arguments

- file:

  A path to a `.pgn` file, or a single character string of 'PGN' text
  when `text = TRUE`.

- text:

  If `TRUE`, treat `file` as literal 'PGN' text rather than a path.

- call:

  The execution environment, for error reporting. Experts only.

## Value

A [gm_game](https://r-heller.github.io/gambitR/reference/gm_game.md)
object.

## Details

Comments (`{...}` and `;` to end of line), numeric annotation glyphs
(`$1`), move numbers and recursive variations (`(...)`) are stripped,
and the remaining mainline tokens are replayed through
[`gm_move()`](https://r-heller.github.io/gambitR/reference/gm_move.md),
so an illegal or ambiguous move is reported where it occurs. A `FEN` tag
is honoured as the starting position.

## See also

Other io:
[`gm_read_fen()`](https://r-heller.github.io/gambitR/reference/gm_read_fen.md),
[`gm_write_fen()`](https://r-heller.github.io/gambitR/reference/gm_write_fen.md),
[`gm_write_pgn()`](https://r-heller.github.io/gambitR/reference/gm_write_pgn.md)

## Examples

``` r
pgn <- "1. e4 e5 2. Nf3 Nc6 *"
gm_read_pgn(pgn, text = TRUE)
#> <gm_game> — 4 half-moves, result "*"
#> 1. e4 e5 2. Nf3 Nc6 *
```
