# Evaluate a position

Static heuristic evaluation from White's perspective: material balance
plus piece-square tables, mobility and simple king-safety terms.
Positive favours White, negative favours Black, in centipawns.

## Usage

``` r
gm_evaluate(position, weights = NULL)
```

## Arguments

- position:

  A
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
  object.

- weights:

  A named list of term weights with any of the elements `material`,
  `mobility` and `king_safety`. If `NULL` (default), package defaults
  are used.

## Value

A length-1 numeric score in centipawns.

## Details

The score is the weighted sum of three terms. `material` scales the
piece values (pawn 100, knight 320, bishop 330, rook 500, queen 900)
together with the piece-square bonuses; `mobility` scales the difference
in the number of legal moves available to each side; and `king_safety`
scales the difference in pawn shelter in front of each king. The
function is colour-symmetric: mirroring a position negates its score.

## See also

Other analysis:
[`gm_bestmove()`](https://r-heller.github.io/gambitR/reference/gm_bestmove.md),
[`gm_uci_bestmove()`](https://r-heller.github.io/gambitR/reference/gm_uci_bestmove.md)

## Examples

``` r
gm_evaluate(gm_position())
#> [1] 0

# A queen up for White
gm_evaluate(gm_position("rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"))
#> [1] 876
```
