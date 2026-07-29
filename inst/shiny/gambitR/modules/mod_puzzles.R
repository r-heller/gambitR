# Module: puzzles

mod_puzzles_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::helpText("puzzles controls")
      # TODO(build): puzzles-specific inputs
    ),
    bslib::card(
      bslib::card_header("puzzles"),
      shiny::plotOutput(ns("board"))
      # TODO(build): puzzles-specific outputs
    )
  )
}

mod_puzzles_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(position = gambitR::gm_position())
    output$board <- shiny::renderPlot({
      tryCatch(
        gambitR::gm_plot_board(rv$position),
        error = function(e) NULL
      )
    })
    # TODO(build): puzzles reactivity
  })
}
