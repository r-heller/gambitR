# Check a puzzle solution attempt

Check a puzzle solution attempt

## Usage

``` r
gm_check_solution(puzzle, moves)
```

## Arguments

- puzzle:

  A `gm_puzzle` object, as returned by
  [`gm_puzzle()`](https://r-heller.github.io/gambitR/reference/gm_puzzle.md).

- moves:

  A character vector of attempted moves in standard algebraic notation.

## Value

A one-row
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with `correct` (logical), `solved_plies` (integer, how many correct
moves matched) and `total_plies` (integer).

## See also

Other puzzles:
[`gm_puzzle()`](https://r-heller.github.io/gambitR/reference/gm_puzzle.md)

## Examples

``` r
p <- gm_puzzle(id = "gm-0001")
gm_check_solution(p, character())
#> # A tibble: 1 × 3
#>   correct solved_plies total_plies
#>   <lgl>          <int>       <int>
#> 1 FALSE              0           1
gm_check_solution(p, p$solution)
#> # A tibble: 1 × 3
#>   correct solved_plies total_plies
#>   <lgl>          <int>       <int>
#> 1 TRUE               1           1
```
