#' Launch the gambitR Shiny application
#'
#' Start the interactive study application with six tabs: Play (versus the
#' engine), Analyse (evaluation and 'PGN' review), Simulate (batch strategy
#' tournaments), Openings (ECO explorer), Puzzles (tactical trainer) and Study
#' (annotate and save games).
#'
#' @param ... Additional arguments passed to [shiny::runApp()].
#' @return Invisible `NULL`. Launches a 'Shiny' application in the browser.
#' @export
#' @family shiny
#' @examples
#' if (interactive()) {
#'   gm_run_app()
#' }
gm_run_app <- function(...) {
  for (pkg in c("shiny", "bslib")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cli::cli_abort(c(
        "Package {.pkg {pkg}} is required to run the app.",
        "i" = "Install it with {.code install.packages('{pkg}')}."
      ))
    }
  }
  app_dir <- system.file("shiny", "gambitR", package = "gambitR")
  if (!nzchar(app_dir)) {
    cli::cli_abort("Could not locate the Shiny app directory.")
  }
  shiny::runApp(app_dir, ...)
  invisible(NULL)
}
