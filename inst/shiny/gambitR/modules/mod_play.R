# Module: play

mod_play_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::helpText("play controls")
      # TODO(build): play-specific inputs
    ),
    bslib::card(
      bslib::card_header("play"),
      shiny::plotOutput(ns("board"))
      # TODO(build): play-specific outputs
    )
  )
}

mod_play_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(position = gambitR::gm_position())
    output$board <- shiny::renderPlot({
      tryCatch(
        gambitR::gm_plot_board(rv$position),
        error = function(e) NULL
      )
    })
    # TODO(build): play reactivity
  })
}
