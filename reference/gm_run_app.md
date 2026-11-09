# Launch the gambitR Shiny application

Start the interactive study application with six tabs: Play (versus the
engine), Analyse (evaluation and 'PGN' review), Simulate (batch strategy
tournaments), Openings (ECO explorer), Puzzles (tactical trainer) and
Study (annotate and save games).

## Usage

``` r
gm_run_app(...)
```

## Arguments

- ...:

  Additional arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

Invisible `NULL`. Launches a 'Shiny' application in the browser.

## Examples

``` r
if (interactive()) {
  gm_run_app()
}
```
