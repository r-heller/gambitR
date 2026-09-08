# Load a tactical puzzle

Draw a puzzle from the bundled set: a position with a known best move or
mating sequence.

## Usage

``` r
gm_puzzle(id = NULL, theme = NULL, seed = NULL)
```

## Arguments

- id:

  Puzzle id, or `NULL` (default) to draw at random.

- theme:

  Optional theme filter (e.g. `"fork"`, `"mateIn2"`).

- seed:

  Optional integer seed for reproducible random draws.

## Value

A `gm_puzzle` object: a list with `position`
([gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)),
`solution` (character vector of SAN moves), `theme` and `rating`.

## Details

The set ships as `inst/extdata/puzzles.rds` and is built by
`data-raw/puzzles.R`, which checks every solution against the move
generator: each move must be legal in turn, every forced reply must be
the opponent's only legal move, and any line ending in `#` must really
end in checkmate.

## See also

Other puzzles:
[`gm_check_solution()`](https://r-heller.github.io/gambitR/reference/gm_check_solution.md)

## Examples

``` r
p <- gm_puzzle(seed = 1)
p$theme
#> [1] "skewer"
p$solution
#> [1] "Bd4+"

gm_puzzle(id = "gm-0001")$solution
#> [1] "Ra8#"
```
