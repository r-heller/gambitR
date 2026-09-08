# Simulate many games between strategies

Batch tournament driver: play `n` games between two strategies and
return a tidy summary of outcomes.

## Usage

``` r
gm_simulate(
  white = "random",
  black = "random",
  n = 10L,
  max_moves = 200L,
  verbose = TRUE
)
```

## Arguments

- white, black:

  Strategy functions or shortcuts, as in
  [`gm_play()`](https://r-heller.github.io/gambitR/reference/gm_play.md).

- n:

  Number of games. Default `10`.

- max_moves:

  Maximum full moves per game. Default `200`.

- verbose:

  If `TRUE` (default), show a progress bar.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per game and columns `game` (integer), `result` (`"1-0"`,
`"0-1"`, `"1/2-1/2"`), `plies` (integer) and `termination` (character).

## See also

Other play:
[`gm_play()`](https://r-heller.github.io/gambitR/reference/gm_play.md)

## Examples

``` r
# \donttest{
gm_simulate(white = "random", black = "random", n = 3, max_moves = 20, verbose = FALSE)
#> # A tibble: 3 × 4
#>    game result  plies termination
#>   <int> <chr>   <int> <chr>      
#> 1     1 1/2-1/2    40 move limit 
#> 2     2 1/2-1/2    40 move limit 
#> 3     3 1/2-1/2    40 move limit 
# }
```
