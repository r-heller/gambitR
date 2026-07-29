# Module: openings - explore the bundled ECO book.

mod_openings_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 320,
      shiny::helpText("Search the ECO book by name or code, then load a line on the board."),
      shiny::textInput(ns("query"), "Name contains", placeholder = "Sicilian"),
      shiny::textInput(ns("eco"), "ECO code starts with", placeholder = "B2"),
      shiny::selectInput(ns("line"), "Line", choices = character(0L)),
      shiny::sliderInput(ns("ply"), "Ply", min = 0L, max = 0L, value = 0L, step = 1L),
      gm_toggle(ns("flip"), "Flip board")
    ),
    bslib::layout_columns(
      col_widths = c(5, 7),
      bslib::card(
        bslib::card_header("Board"),
        shiny::plotOutput(ns("board"), height = "420px"),
        shiny::verbatimTextOutput(ns("line_moves"))
      ),
      bslib::card(
        bslib::card_header("Matching openings"),
        shiny::tableOutput(ns("table"))
      )
    )
  )
}

mod_openings_server <- function(id, store = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(position = gambitR::gm_position())

    matches <- shiny::reactive({
      query <- trimws(input$query %|OR|% "")
      eco <- trimws(input$eco %|OR|% "")
      tryCatch(
        gambitR::gm_openings(
          query = if (nzchar(query)) query else NULL,
          eco = if (nzchar(eco)) eco else NULL
        ),
        error = function(e) gambitR::gm_openings(query = "a name that cannot match")
      )
    })

    shiny::observe({
      book <- matches()
      choices <- if (nrow(book)) {
        stats::setNames(book$name, paste0(book$eco, "  ", book$name))
      } else {
        character(0L)
      }
      shiny::updateSelectInput(session, "line", choices = choices)
    })

    selected <- shiny::reactive({
      book <- matches()
      shiny::req(nrow(book) > 0L)
      hit <- book[book$name == (input$line %|OR|% ""), , drop = FALSE]
      if (nrow(hit) == 0L) hit <- book[1L, , drop = FALSE]
      hit
    })

    line_moves <- shiny::reactive({
      hit <- selected()
      strsplit(hit$moves[[1L]], " ", fixed = TRUE)[[1L]]
    })

    shiny::observe({
      moves <- line_moves()
      shiny::updateSliderInput(
        session, "ply",
        min = 0L, max = length(moves), value = length(moves)
      )
    })

    shiny::observe({
      moves <- line_moves()
      ply <- min(input$ply %|OR|% length(moves), length(moves))
      position <- gambitR::gm_position()
      out <- tryCatch(
        {
          for (san in utils::head(moves, ply)) {
            position <- gambitR::gm_move(position, san)
          }
          position
        },
        error = function(e) NULL
      )
      if (!is.null(out)) {
        rv$position <- out
        if (!is.null(store)) store$position <- out
      }
    })

    output$board <- shiny::renderPlot({
      shiny::req(rv$position)
      gm_safe_board(rv$position, flip = isTRUE(input$flip))
    })

    output$line_moves <- shiny::renderText({
      tryCatch(
        {
          hit <- selected()
          paste0(
            hit$eco[[1L]], "  ", hit$name[[1L]], "\n",
            gm_movetext(line_moves())
          )
        },
        error = function(e) ""
      )
    })

    output$table <- shiny::renderTable({
      tryCatch(
        {
          book <- matches()
          shiny::req(nrow(book) > 0L)
          out <- book[, c("eco", "name", "moves")]
          utils::head(out, 40L)
        },
        error = function(e) NULL
      )
    })
  })
}
