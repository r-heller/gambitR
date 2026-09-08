# Chess games

A `gm_game` is the S3 container returned by
[`gm_read_pgn()`](https://r-heller.github.io/gambitR/reference/gm_read_pgn.md),
[`gm_play()`](https://r-heller.github.io/gambitR/reference/gm_play.md)
and the study tools. It is a list with four elements:

## Details

- `moves`:

  Character vector of mainline moves in standard algebraic notation, one
  per half-move.

- `positions`:

  List of
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
  objects, one longer than `moves`: the starting position followed by
  the position after each move.

- `tags`:

  Named list of 'PGN' header tags, e.g. `Event` or `White`.

- `result`:

  One of `"1-0"`, `"0-1"`, `"1/2-1/2"` or `"*"`.

Use
[`is_gm_game()`](https://r-heller.github.io/gambitR/reference/is_gm_game.md)
to test for the class,
[`gm_write_pgn()`](https://r-heller.github.io/gambitR/reference/gm_write_pgn.md)
to serialise it and
[`gm_plot_eval()`](https://r-heller.github.io/gambitR/reference/gm_plot_eval.md)
to visualise how the evaluation moved.

## See also

Other core:
[`gm_legal_moves()`](https://r-heller.github.io/gambitR/reference/gm_legal_moves.md),
[`gm_move()`](https://r-heller.github.io/gambitR/reference/gm_move.md),
[`gm_position()`](https://r-heller.github.io/gambitR/reference/gm_position.md),
[`gm_status()`](https://r-heller.github.io/gambitR/reference/gm_status.md),
[`is_gm_game()`](https://r-heller.github.io/gambitR/reference/is_gm_game.md),
[`is_gm_position()`](https://r-heller.github.io/gambitR/reference/is_gm_position.md)

## Examples

``` r
game <- gm_read_pgn("1. e4 e5 2. Nf3 Nc6 *", text = TRUE)
game$moves
#> [1] "e4"  "e5"  "Nf3" "Nc6"
game$result
#> [1] "*"
```
