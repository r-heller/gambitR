# Module: study

mod_study_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::helpText("study controls")
      # TODO(build): study-specific inputs
    ),
    bslib::card(
      bslib::card_header("study"),
      shiny::plotOutput(ns("board"))
      # TODO(build): study-specific outputs
    )
  )
}

mod_study_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(position = gambitR::gm_position())
    output$board <- shiny::renderPlot({
      tryCatch(
        gambitR::gm_plot_board(rv$position),
        error = function(e) NULL
      )
    })
    # TODO(build): study reactivity
  })
}
