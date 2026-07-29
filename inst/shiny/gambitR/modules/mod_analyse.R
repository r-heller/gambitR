# Module: analyse

mod_analyse_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::helpText("analyse controls")
      # TODO(build): analyse-specific inputs
    ),
    bslib::card(
      bslib::card_header("analyse"),
      shiny::plotOutput(ns("board"))
      # TODO(build): analyse-specific outputs
    )
  )
}

mod_analyse_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(position = gambitR::gm_position())
    output$board <- shiny::renderPlot({
      tryCatch(
        gambitR::gm_plot_board(rv$position),
        error = function(e) NULL
      )
    })
    # TODO(build): analyse reactivity
  })
}
