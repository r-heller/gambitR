# Look up openings by name or moves

Query the bundled ECO opening book.

## Usage

``` r
gm_openings(query = NULL, eco = NULL)
```

## Arguments

- query:

  A search string matched against opening names (e.g. `"Sicilian"`), or
  `NULL` (default) to return the whole book.

- eco:

  Optional ECO code filter (e.g. `"B20"`).

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `eco` (character), `name` (character), `moves` (character,
space-separated SAN) and `fen` (character, resulting position). Zero
rows when nothing matches.

## Details

The book ships with the package as `inst/extdata/eco.rds` and is built
by `data-raw/eco.R`, which replays every line through
[`gm_move()`](https://r-heller.github.io/gambitR/reference/gm_move.md)
so that no unplayable sequence can reach it. `eco` is matched as a
prefix, so `eco = "B2"` returns the whole of the B20-B29 range.

## See also

Other openings:
[`gm_identify_opening()`](https://r-heller.github.io/gambitR/reference/gm_identify_opening.md)

## Examples

``` r
gm_openings("Sicilian")
#> # A tibble: 25 × 4
#>    eco   name                                                      moves   fen  
#>    <chr> <chr>                                                     <chr>   <chr>
#>  1 A08   King's Indian Attack, Sicilian Variation                  Nf3 d5… rnbq…
#>  2 A21   English Opening, King's English, Reversed Sicilian        c4 e5 … rnbq…
#>  3 A25   English Opening, King's English, Reversed Closed Sicilian c4 e5 … r1bq…
#>  4 B20   Sicilian Defense                                          e4 c5   rnbq…
#>  5 B21   Sicilian Defense, Smith-Morra Gambit                      e4 c5 … rnbq…
#>  6 B22   Sicilian Defense, Alapin Variation                        e4 c5 … rnbq…
#>  7 B23   Sicilian Defense, Closed Variation                        e4 c5 … rnbq…
#>  8 B27   Sicilian Defense, Hyperaccelerated Dragon                 e4 c5 … rnbq…
#>  9 B29   Sicilian Defense, Nimzo-American Variation                e4 c5 … rnbq…
#> 10 B30   Sicilian Defense, Old Sicilian                            e4 c5 … r1bq…
#> # ℹ 15 more rows
gm_openings(eco = "C6")
#> # A tibble: 5 × 4
#>   eco   name                            moves                     fen           
#>   <chr> <chr>                           <chr>                     <chr>         
#> 1 C60   Ruy Lopez                       e4 e5 Nf3 Nc6 Bb5         r1bqkbnr/pppp…
#> 2 C62   Ruy Lopez, Old Steinitz Defense e4 e5 Nf3 Nc6 Bb5 d6      r1bqkbnr/ppp2…
#> 3 C64   Ruy Lopez, Classical Variation  e4 e5 Nf3 Nc6 Bb5 Bc5     r1bqk1nr/pppp…
#> 4 C65   Ruy Lopez, Berlin Defense       e4 e5 Nf3 Nc6 Bb5 Nf6     r1bqkb1r/pppp…
#> 5 C68   Ruy Lopez, Exchange Variation   e4 e5 Nf3 Nc6 Bb5 a6 Bxc6 r1bqkbnr/1ppp…
```
