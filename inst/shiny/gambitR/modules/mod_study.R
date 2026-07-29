# Module: study - step through a game, annotate it and export it.

mod_study_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 320,
      shiny::helpText("Load a game, walk through it and add notes, then export the PGN."),
      shiny::textAreaInput(ns("pgn"), "PGN", value = "", rows = 5),
      shiny::actionButton(ns("load"), "Load PGN", class = "btn-primary w-100"),
      shiny::actionButton(
        ns("from_play"), "Take game from Play tab",
        class = "btn-outline-secondary w-100 mt-2"
      ),
      shiny::hr(),
      shiny::textInput(ns("san"), "Add a move", placeholder = "e4"),
      shiny::actionButton(ns("add"), "Add", class = "btn-outline-secondary w-100"),
      shiny::hr(),
      shiny::textInput(ns("event"), "Event", value = "gambitR study"),
      shiny::textInput(ns("white"), "White", value = "?"),
      shiny::textInput(ns("black"), "Black", value = "?"),
      shiny::downloadButton(
        ns("download"), "Download PGN",
        class = "btn-outline-secondary w-100"
      )
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      gm_board_card(
        "Position", ns("board"), height = "470px",
        shiny::div(
          class = "gm-ply-bar",
          shiny::div(
            class = "gm-nav-group",
            shiny::actionButton(
              ns("prev"), "Previous",
              class = "btn-outline-secondary btn-sm"
            ),
            shiny::actionButton(
              ns("next_ply"), "Next",
              class = "btn-outline-secondary btn-sm"
            )
          ),
          shiny::sliderInput(
            ns("ply"), NULL,
            min = 0L, max = 0L, value = 0L, step = 1L,
            ticks = FALSE, width = "100%"
          )
        )
      ),
      gm_stack(
        gm_text_card(
          "Annotation for this ply",
          shiny::textAreaInput(ns("note"), NULL, value = "", rows = 3),
          shiny::div(
            shiny::actionButton(ns("save_note"), "Save note", class = "btn-primary")
          )
        ),
        gm_text_card("Game", shiny::uiOutput(ns("pgn_out")))
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

    output$board <- shiny::renderPlot(
      {
        shiny::req(length(rv$positions) > 0L)
        index <- min(rv$ply + 1L, length(rv$positions))
        gm_safe_board(rv$positions[[index]])
      },
      res = 96
    )

    # The status line is chrome, the PGN is the document: keep them apart
    # instead of pasting the message into the middle of the export.
    output$pgn_out <- shiny::renderUI({
      tryCatch(
        {
          pgn <- gambitR::gm_write_pgn(game())
          notes <- rv$notes[nzchar(rv$notes)]
          shiny::tagList(
            shiny::div(
              class = "gm-meta mb-2",
              paste0(
                rv$message, "  ·  ply ", rv$ply, " of ", length(rv$moves)
              )
            ),
            shiny::tags$pre(class = "gm-scroll", pgn),
            if (length(notes)) {
              shiny::tagList(
                shiny::div(class = "gm-subhead mt-3", "Notes"),
                shiny::tags$ul(
                  class = "gm-notes",
                  lapply(notes, shiny::tags$li)
                )
              )
            }
          )
        },
        error = function(e) gm_empty(conditionMessage(e))
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
