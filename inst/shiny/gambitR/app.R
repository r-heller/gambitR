# gambitR Shiny application entry point.
# No library() calls: everything is namespace-qualified via gambitR:: or pkg::.

.module_files <- list.files(
  file.path("modules"), pattern = "\\.R$", full.names = TRUE
)
for (.f in .module_files) source(.f, local = TRUE)

ui <- bslib::page_navbar(
  title = "gambitR",
  theme = bslib::bs_theme(version = 5, primary = "#5E2C8E"),
  bslib::nav_panel("Play",      mod_play_ui("play")),
  bslib::nav_panel("Analyse",   mod_analyse_ui("analyse")),
  bslib::nav_panel("Simulate",  mod_simulate_ui("simulate")),
  bslib::nav_panel("Openings",  mod_openings_ui("openings")),
  bslib::nav_panel("Puzzles",   mod_puzzles_ui("puzzles")),
  bslib::nav_panel("Study",     mod_study_ui("study"))
)

server <- function(input, output, session) {
  mod_play_server("play")
  mod_analyse_server("analyse")
  mod_simulate_server("simulate")
  mod_openings_server("openings")
  mod_puzzles_server("puzzles")
  mod_study_server("study")
}

shiny::shinyApp(ui, server)
