# Module: analyse - evaluate a position or review a whole game.

mod_analyse_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 320,
      shiny::helpText("Paste a FEN or a PGN, or pull in the game from the Play tab."),
      shiny::textAreaInput(
        ns("input_text"), "FEN or PGN",
        value = "", rows = 5,
        placeholder = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      ),
      shiny::actionButton(ns("load"), "Load", class = "btn-primary w-100"),
      shiny::actionButton(
        ns("from_play"), "Take game from Play tab",
        class = "btn-outline-secondary w-100 mt-2"
      ),
      shiny::hr(),
      shiny::sliderInput(
        ns("depth"), "Search depth",
        min = 1L, max = 3L, value = 2L, step = 1L, ticks = FALSE
      ),
      gm_toggle(ns("uci"), "Use external UCI engine"),
      shiny::div(class = "gm-meta", shiny::textOutput(ns("uci_note")))
    ),
    bslib::layout_columns(
      col_widths = c(5, 7),
      gm_board_card("Position", ns("board"), height = "460px"),
      gm_stack(
        gm_text_card("Evaluation", shiny::uiOutput(ns("eval"))),
        gm_text_card("Evaluation curve", shiny::uiOutput(ns("curve_ui")))
      )
    )
  )
}

mod_analyse_server <- function(id, store = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(
      position = gambitR::gm_position(),
      game = NULL,
      note = "Start position loaded."
    )

    load_text <- function(text) {
      text <- trimws(text)
      if (!nzchar(text)) {
        return(invisible(NULL))
      }
      if (grepl("^[rnbqkpRNBQKP1-8/]+\\s+[wb]\\s", text)) {
        position <- tryCatch(gambitR::gm_read_fen(text), error = function(e) e)
        if (inherits(position, "error")) {
          rv$note <- conditionMessage(position)
          return(invisible(NULL))
        }
        rv$position <- position
        rv$game <- NULL
        rv$note <- "FEN loaded."
        return(invisible(NULL))
      }
      game <- tryCatch(gambitR::gm_read_pgn(text, text = TRUE), error = function(e) e)
      if (inherits(game, "error")) {
        rv$note <- conditionMessage(game)
        return(invisible(NULL))
      }
      rv$game <- game
      rv$position <- game$positions[[length(game$positions)]]
      rv$note <- paste0("PGN loaded: ", length(game$moves), " half-moves.")
      invisible(NULL)
    }

    shiny::observeEvent(input$load, load_text(input$input_text %|OR|% ""))

    shiny::observeEvent(input$from_play, {
      shiny::req(!is.null(store))
      game <- store$game
      if (is.null(game) || !gambitR::is_gm_game(game)) {
        rv$note <- "No game has been played yet."
        return(invisible(NULL))
      }
      rv$game <- game
      rv$position <- game$positions[[length(game$positions)]]
      rv$note <- paste0("Loaded ", length(game$moves), " half-moves from Play.")
    })

    best <- shiny::reactive({
      shiny::req(rv$position)
      engine <- if (isTRUE(input$uci) && gm_uci_available()) "uci" else "native"
      tryCatch(
        gambitR::gm_bestmove(
          rv$position,
          depth = input$depth %|OR|% 2L, engine = engine, verbose = FALSE
        ),
        error = function(e) NULL
      )
    })

    output$uci_note <- shiny::renderText({
      tryCatch(
        if (gm_uci_available()) {
          "An external UCI engine is available."
        } else {
          "No external UCI engine found; the native engine is used."
        },
        error = function(e) ""
      )
    })

    output$board <- shiny::renderPlot(
      {
        shiny::req(rv$position)
        gm_safe_board(rv$position)
      },
      res = 96
    )

    output$eval <- shiny::renderUI({
      shiny::req(rv$position)
      tryCatch(
        {
          static <- gambitR::gm_evaluate(rv$position)
          line <- best()
          shiny::tagList(
            shiny::div(class = "gm-status", gm_status_text(rv$position)),
            shiny::tags$pre(paste(
              c(
                paste0("Static evaluation   ", sprintf("%+d cp", round(static))),
                if (!is.null(line) && !is.na(line$san)) {
                  paste0(
                    "Best move           ", line$san,
                    "  (", sprintf("%+d", round(line$score)), " cp, depth ",
                    line$depth, ")"
                  )
                } else {
                  "Best move           none — the game is over"
                }
              ),
              collapse = "\n"
            )),
            shiny::div(class = "gm-meta mt-2", rv$note)
          )
        },
        error = function(e) gm_empty(conditionMessage(e))
      )
    })

    output$curve_ui <- shiny::renderUI({
      ns <- session$ns
      if (is.null(rv$game) || !length(rv$game$moves)) {
        gm_empty("Load a PGN, or take the game from the Play tab, to see the curve.")
      } else {
        shiny::plotOutput(ns("curve"), height = "300px")
      }
    })

    output$curve <- shiny::renderPlot(
      {
        shiny::req(rv$game)
        shiny::req(length(rv$game$moves) > 0L)
        gm_safe_eval(rv$game)
      },
      res = 96
    )
  })
}
