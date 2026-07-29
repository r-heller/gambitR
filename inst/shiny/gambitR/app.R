# gambitR Shiny application entry point.
# No library() calls: everything is namespace-qualified via gambitR:: or pkg::.

.module_dir <- if (dir.exists("modules")) {
  "modules"
} else {
  system.file("shiny", "gambitR", "modules", package = "gambitR")
}

for (.f in sort(list.files(.module_dir, pattern = "\\.R$", full.names = TRUE))) {
  source(.f, local = FALSE)
}

ui <- bslib::page_navbar(
  title = "gambitR",
  theme = bslib::bs_theme(version = 5, primary = gm_accent),
  header = shiny::tags$head(
    shiny::tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  bslib::nav_panel("Play", mod_play_ui("play")),
  bslib::nav_panel("Analyse", mod_analyse_ui("analyse")),
  bslib::nav_panel("Simulate", mod_simulate_ui("simulate")),
  bslib::nav_panel("Openings", mod_openings_ui("openings")),
  bslib::nav_panel("Puzzles", mod_puzzles_ui("puzzles")),
  bslib::nav_panel("Study", mod_study_ui("study")),
  bslib::nav_spacer(),
  bslib::nav_item(
    shiny::tags$img(
      src = "logo.png", height = "34px", alt = "gambitR",
      class = "gm-logo"
    )
  )
)

server <- function(input, output, session) {
  # Cross-module state: the Play tab publishes its game, Analyse and Study
  # consume it, and Openings publishes the position it is showing.
  store <- shiny::reactiveValues(game = NULL, position = NULL, simulation = NULL)

  mod_play_server("play", store)
  mod_analyse_server("analyse", store)
  mod_simulate_server("simulate", store)
  mod_openings_server("openings", store)
  mod_puzzles_server("puzzles", store)
  mod_study_server("study", store)
}

shiny::shinyApp(ui, server)
