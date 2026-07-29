# Module: openings

mod_openings_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::helpText("openings controls")
      # TODO(build): openings-specific inputs
    ),
    bslib::card(
      bslib::card_header("openings"),
      shiny::plotOutput(ns("board"))
      # TODO(build): openings-specific outputs
    )
  )
}

mod_openings_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(position = gambitR::gm_position())
    output$board <- shiny::renderPlot({
      tryCatch(
        gambitR::gm_plot_board(rv$position),
        error = function(e) NULL
      )
    })
    # TODO(build): openings reactivity
  })
}
