# Module: study - step through a game, annotate it and export it.

mod_study_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 320,
      shiny::helpText("Load a game, walk through it and add notes, then export the PGN."),
      shiny::textAreaInput(ns("pgn"), "PGN", value = "", rows = 5),
      shiny::actionButton(ns("load"), "Load PGN", class = "btn-primary w-100"),
      shiny::actionButton(ns("from_play"), "Take game from Play tab", class = "w-100 mt-2"),
      shiny::hr(),
      shiny::textInput(ns("san"), "Add a move", placeholder = "e4"),
      shiny::actionButton(ns("add"), "Add", class = "w-100"),
      shiny::hr(),
      shiny::textInput(ns("event"), "Event", value = "gambitR study"),
      shiny::textInput(ns("white"), "White", value = "?"),
      shiny::textInput(ns("black"), "Black", value = "?"),
      shiny::downloadButton(ns("download"), "Download PGN", class = "w-100")
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(
        bslib::card_header("Position"),
        shiny::plotOutput(ns("board"), height = "420px"),
        shiny::sliderInput(ns("ply"), "Ply", min = 0L, max = 0L, value = 0L, step = 1L),
        shiny::actionButton(ns("prev"), "Previous"),
        shiny::actionButton(ns("next_ply"), "Next")
      ),
      bslib::layout_columns(
        col_widths = 12,
        bslib::card(
          bslib::card_header("Annotation for this ply"),
          shiny::textAreaInput(ns("note"), NULL, value = "", rows = 3),
          shiny::actionButton(ns("save_note"), "Save note")
        ),
        bslib::card(
          bslib::card_header("Game"),
          shiny::verbatimTextOutput(ns("pgn_out"))
        )
      )
    )
  )
}

mod_study_server <- function(id, store = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    start <- gambitR::gm_position()
    rv <- shiny::reactiveValues(
      moves = character(0L),
      positions = list(start),
      notes = character(0L),
      ply = 0L,
      message = "Empty study. Load a PGN or add moves."
    )

    set_game <- function(game) {
      rv$moves <- game$moves
      rv$positions <- game$positions
      rv$notes <- rep("", length(game$moves) + 1L)
      rv$ply <- length(game$moves)
      rv$message <- paste0("Loaded ", length(game$moves), " half-moves.")
    }

    shiny::observeEvent(input$load, {
      text <- trimws(input$pgn %|OR|% "")
      shiny::req(nzchar(text))
      game <- tryCatch(gambitR::gm_read_pgn(text, text = TRUE), error = function(e) e)
      if (inherits(game, "error")) {
        rv$message <- conditionMessage(game)
        return(invisible(NULL))
      }
      set_game(game)
    })

    shiny::observeEvent(input$from_play, {
      shiny::req(!is.null(store))
      game <- store$game
      if (is.null(game) || !gambitR::is_gm_game(game)) {
        rv$message <- "No game has been played yet."
        return(invisible(NULL))
      }
      set_game(game)
    })

    shiny::observeEvent(input$add, {
      shiny::req(input$san)
      san <- trimws(input$san)
      shiny::req(nzchar(san))
      current <- rv$positions[[length(rv$positions)]]
      out <- tryCatch(gambitR::gm_move(current, san), error = function(e) e)
      if (inherits(out, "error")) {
        rv$message <- conditionMessage(out)
        return(invisible(NULL))
      }
      rv$moves <- c(rv$moves, san)
      rv$positions <- c(rv$positions, list(out))
      rv$notes <- c(rv$notes, "")
      rv$ply <- length(rv$moves)
      rv$message <- paste0("Added ", san, ".")
      shiny::updateTextInput(session, "san", value = "")
    })

    shiny::observe({
      shiny::updateSliderInput(
        session, "ply",
        min = 0L, max = length(rv$moves), value = rv$ply
      )
    })

    shiny::observeEvent(input$ply, {
      value <- input$ply
      if (!is.null(value) && value >= 0L && value <= length(rv$moves)) {
        rv$ply <- as.integer(value)
      }
    })

    shiny::observeEvent(input$prev, {
      rv$ply <- max(0L, rv$ply - 1L)
      shiny::updateSliderInput(session, "ply", value = rv$ply)
    })

    shiny::observeEvent(input$next_ply, {
      rv$ply <- min(length(rv$moves), rv$ply + 1L)
      shiny::updateSliderInput(session, "ply", value = rv$ply)
    })

    shiny::observeEvent(rv$ply, {
      index <- rv$ply + 1L
      note <- if (index <= length(rv$notes)) rv$notes[[index]] else ""
      shiny::updateTextAreaInput(session, "note", value = note)
    })

    shiny::observeEvent(input$save_note, {
      index <- rv$ply + 1L
      if (length(rv$notes) < index) {
        rv$notes <- c(rv$notes, rep("", index - length(rv$notes)))
      }
      rv$notes[[index]] <- input$note %|OR|% ""
      rv$message <- paste0("Saved the note on ply ", rv$ply, ".")
    })

    game <- shiny::reactive({
      out <- gm_game_from_moves(rv$moves, rv$positions)
      out$tags <- list(
        Event = input$event %|OR|% "gambitR study",
        Site = "gambitR",
        Date = format(Sys.Date(), "%Y.%m.%d"),
        Round = "1",
        White = input$white %|OR|% "?",
        Black = input$black %|OR|% "?",
        Result = "*"
      )
      out
    })

    output$board <- shiny::renderPlot({
      shiny::req(length(rv$positions) > 0L)
      index <- min(rv$ply + 1L, length(rv$positions))
      gm_safe_board(rv$positions[[index]])
    })

    output$pgn_out <- shiny::renderText({
      tryCatch(
        {
          pgn <- gambitR::gm_write_pgn(game())
          notes <- rv$notes[nzchar(rv$notes)]
          paste(
            c(
              rv$message, "", pgn,
              if (length(notes)) c("Notes:", notes)
            ),
            collapse = "\n"
          )
        },
        error = function(e) conditionMessage(e)
      )
    })

    output$download <- shiny::downloadHandler(
      filename = function() "gambitR-study.pgn",
      content = function(file) {
        tryCatch(
          gambitR::gm_write_pgn(game(), path = file, overwrite = TRUE),
          error = function(e) writeLines("*", file)
        )
      }
    )
  })
}
