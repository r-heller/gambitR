# Identify the opening of a game

Walk the game's moves against the bundled book and report the deepest
line that the game follows.

## Usage

``` r
gm_identify_opening(game)
```

## Arguments

- game:

  A [gm_game](https://r-heller.github.io/gambitR/reference/gm_game.md)
  object.

## Value

A one-row
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with the matched `eco`, `name` and the ply at which the book line
diverged (`book_depth`). Zero rows if unmatched.

## See also

Other openings:
[`gm_openings()`](https://r-heller.github.io/gambitR/reference/gm_openings.md)

## Examples

``` r
gm_identify_opening(gm_read_pgn("1. e4 c5 *", text = TRUE))
#> # A tibble: 1 × 3
#>   eco   name             book_depth
#>   <chr> <chr>                 <int>
#> 1 B20   Sicilian Defense          2
```
