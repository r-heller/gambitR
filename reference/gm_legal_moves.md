# Generate legal moves

Enumerate every legal move in a position, accounting for checks, pins,
castling, en passant and promotion.

## Usage

``` r
gm_legal_moves(position)
```

## Arguments

- position:

  A
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
  object.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with one row per legal move and columns: `from` (character square, e.g.
`"e2"`), `to` (character square), `piece` (character), `san` (character,
standard algebraic notation), `promotion` (character or `NA`), `flag`
(character: `"normal"`, `"capture"`, `"castle"`, `"ep"`, `"promo"`).
Zero rows in checkmate or stalemate.

## See also

Other core:
[`gm_game`](https://r-heller.github.io/gambitR/reference/gm_game.md),
[`gm_move()`](https://r-heller.github.io/gambitR/reference/gm_move.md),
[`gm_position()`](https://r-heller.github.io/gambitR/reference/gm_position.md),
[`gm_status()`](https://r-heller.github.io/gambitR/reference/gm_status.md),
[`is_gm_game()`](https://r-heller.github.io/gambitR/reference/is_gm_game.md),
[`is_gm_position()`](https://r-heller.github.io/gambitR/reference/is_gm_position.md)

## Examples

``` r
gm_legal_moves(gm_position())
#> # A tibble: 20 × 6
#>    from  to    piece san   promotion flag  
#>    <chr> <chr> <chr> <chr> <chr>     <chr> 
#>  1 a2    a3    P     a3    NA        normal
#>  2 a2    a4    P     a4    NA        normal
#>  3 b2    b3    P     b3    NA        normal
#>  4 b2    b4    P     b4    NA        normal
#>  5 c2    c3    P     c3    NA        normal
#>  6 c2    c4    P     c4    NA        normal
#>  7 d2    d3    P     d3    NA        normal
#>  8 d2    d4    P     d4    NA        normal
#>  9 e2    e3    P     e3    NA        normal
#> 10 e2    e4    P     e4    NA        normal
#> 11 f2    f3    P     f3    NA        normal
#> 12 f2    f4    P     f4    NA        normal
#> 13 g2    g3    P     g3    NA        normal
#> 14 g2    g4    P     g4    NA        normal
#> 15 h2    h3    P     h3    NA        normal
#> 16 h2    h4    P     h4    NA        normal
#> 17 b1    a3    N     Na3   NA        normal
#> 18 b1    c3    N     Nc3   NA        normal
#> 19 g1    f3    N     Nf3   NA        normal
#> 20 g1    h3    N     Nh3   NA        normal
```
