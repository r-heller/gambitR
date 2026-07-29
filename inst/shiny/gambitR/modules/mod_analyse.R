# Module: analyse - evaluate a position or review a whole game.

mod_analyse_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 320,
      shiny::helpText("Paste a FEN or a PGN, or pull in the game from the Play tab."),
      shiny::textAreaInput(
        ns("input_text"), "FEN or PGN",
        value = "", rows = 6,
        placeholder = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      ),
      shiny::actionButton(ns("load"), "Load", class = "btn-primary w-100"),
      shiny::actionButton(ns("from_play"), "Take game from Play tab", class = "w-100 mt-2"),
      shiny::hr(),
      shiny::sliderInput(ns("depth"), "Search depth", min = 1L, max = 3L, value = 2L),
      gm_toggle(ns("uci"), "Use external UCI engine"),
      shiny::helpText(shiny::textOutput(ns("uci_note")))
    ),
    bslib::layout_columns(
      col_widths = c(5, 7),
      bslib::card(
        bslib::card_header("Position"),
        shiny::plotOutput(ns("board"), height = "420px")
      ),
      bslib::layout_columns(
        col_widths = 12,
        bslib::card(
          bslib::card_header("Evaluation"),
          shiny::verbatimTextOutput(ns("eval"))
        ),
        bslib::card(
          bslib::card_header("Evaluation curve"),
          shiny::plotOutput(ns("curve"), height = "240px")
        )
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

    output$board <- shiny::renderPlot({
      shiny::req(rv$position)
      gm_safe_board(rv$position)
    })

    output$eval <- shiny::renderText({
      shiny::req(rv$position)
      tryCatch(
        {
          static <- gambitR::gm_evaluate(rv$position)
          line <- best()
          paste(
            c(
              rv$note,
              paste0("Status: ", gm_status_text(rv$position)),
              paste0("Static evaluation: ", round(static), " cp"),
              if (!is.null(line) && !is.na(line$san)) {
                paste0(
                  "Best move: ", line$san, " (", round(line$score), " cp, depth ",
                  line$depth, ")"
                )
              } else {
                "Best move: none (the game is over)"
              }
            ),
            collapse = "\n"
          )
        },
        error = function(e) conditionMessage(e)
      )
    })

    output$curve <- shiny::renderPlot({
      shiny::req(rv$game)
      shiny::req(length(rv$game$moves) > 0L)
      tryCatch(gambitR::gm_plot_eval(rv$game), error = function(e) NULL)
    })
  })
}
