# Module: openings - explore the bundled ECO book.

# How many book lines the table shows at once. The ECO book has a few hundred
# entries and a card is not a spreadsheet.
.gm_openings_shown <- 40L

mod_openings_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 320,
      shiny::helpText("Search the ECO book by name or code, then load a line on the board."),
      shiny::textInput(ns("query"), "Name contains", placeholder = "Sicilian"),
      shiny::textInput(ns("eco"), "ECO code starts with", placeholder = "B2"),
      shiny::selectInput(ns("line"), "Line", choices = character(0L)),
      shiny::sliderInput(
        ns("ply"), "Ply",
        min = 0L, max = 0L, value = 0L, step = 1L, ticks = FALSE
      ),
      gm_toggle(ns("flip"), "Flip board")
    ),
    bslib::layout_columns(
      col_widths = c(5, 7),
      gm_stack(
        gm_board_card("Board", ns("board"), height = "440px"),
        gm_text_card("Line", shiny::uiOutput(ns("line_moves")))
      ),
      gm_text_card(
        "Matching openings",
        shiny::uiOutput(ns("table_note")),
        shiny::div(class = "gm-table-scroll", shiny::tableOutput(ns("table")))
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

    output$board <- shiny::renderPlot(
      {
        shiny::req(rv$position)
        gm_safe_board(rv$position, flip = isTRUE(input$flip))
      },
      res = 96
    )

    output$line_moves <- shiny::renderUI({
      tryCatch(
        {
          hit <- selected()
          moves <- line_moves()
          ply <- min(input$ply %|OR|% length(moves), length(moves))
          shiny::tagList(
            shiny::div(class = "gm-status", hit$name[[1L]]),
            shiny::div(
              class = "gm-meta mt-1",
              paste0(
                "ECO ", hit$eco[[1L]], " · ", length(moves),
                " half-move", if (length(moves) == 1L) "" else "s",
                " · showing ", ply
              )
            ),
            shiny::tags$pre(class = "mt-2", gm_movetext(moves))
          )
        },
        error = function(e) gm_empty("No line selected.")
      )
    })

    # The table is capped so the card stays usable; say so rather than
    # truncating in silence.
    output$table_note <- shiny::renderUI({
      book <- tryCatch(matches(), error = function(e) NULL)
      total <- if (is.null(book)) 0L else nrow(book)
      if (total == 0L) {
        return(gm_empty("No opening matches that search."))
      }
      shiny::div(
        class = "gm-meta mb-2",
        if (total > .gm_openings_shown) {
          paste0(
            "First ", .gm_openings_shown, " of ", total,
            " matching lines. Narrow the search to see the rest."
          )
        } else {
          paste0(total, " matching line", if (total == 1L) "" else "s", ".")
        }
      )
    })

    output$table <- shiny::renderTable(
      {
        tryCatch(
          {
            book <- matches()
            shiny::req(nrow(book) > 0L)
            out <- utils::head(book[, c("eco", "name", "moves")], .gm_openings_shown)
            names(out) <- c("ECO", "Opening", "Moves")
            out
          },
          error = function(e) NULL
        )
      },
      striped = TRUE, hover = TRUE, spacing = "xs", width = "100%",
      align = "lll"
    )
  })
}
