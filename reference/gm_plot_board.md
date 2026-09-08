# Plot a chess board

Render a position as a `ggplot2` object: an 8x8 board with the pieces
drawn as vector shapes. Returns the plot for further customisation;
never draws directly. Drop the annotations with
`gm_plot_board(p) + ggplot2::labs(title = NULL, subtitle = NULL)`, or
add the `FEN` yourself with
`gm_plot_board(p) + ggplot2::labs(caption = gm_write_fen(p))`.

## Usage

``` r
gm_plot_board(position, highlight = NULL, flip = FALSE)
```

## Arguments

- position:

  A
  [gm_position](https://r-heller.github.io/gambitR/reference/gm_position.md)
  object.

- highlight:

  Optional character vector of squares to highlight (e.g.
  `c("e4", "d5")`).

- flip:

  If `TRUE`, view from Black's side. Default `FALSE`.

## Value

A `ggplot2` object.

## Details

The pieces are polygons rather than text, so they scale with the square
and stay legible from a 2-inch figure to a full page, and the board
renders on every graphics device including pdf and postscript.

## See also

Other visualization:
[`gm_plot_eval()`](https://r-heller.github.io/gambitR/reference/gm_plot_eval.md)

## Examples

``` r
gm_plot_board(gm_position())


# Highlight the squares of a move
gm_plot_board(gm_move(gm_position(), "e4"), highlight = c("e2", "e4"))
```
