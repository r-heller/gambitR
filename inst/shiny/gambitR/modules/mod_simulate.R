# Module: simulate

mod_simulate_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::helpText("simulate controls")
      # TODO(build): simulate-specific inputs
    ),
    bslib::card(
      bslib::card_header("simulate"),
      shiny::plotOutput(ns("board"))
      # TODO(build): simulate-specific outputs
    )
  )
}

mod_simulate_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(position = gambitR::gm_position())
    output$board <- shiny::renderPlot({
      tryCatch(
        gambitR::gm_plot_board(rv$position),
        error = function(e) NULL
      )
    })
    # TODO(build): simulate reactivity
  })
}
