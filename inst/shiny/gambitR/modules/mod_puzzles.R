# Module: puzzles - the tactical trainer.

mod_puzzles_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 300,
      shiny::helpText("Find the move. Click the pieces or type algebraic notation."),
      shiny::selectInput(ns("theme"), "Theme", choices = c("any")),
      shiny::actionButton(
        ns("new"), "New puzzle",
        class = "btn-outline-secondary w-100"
      ),
      shiny::hr(),
      shiny::textInput(ns("san"), "Your move", placeholder = "Ra8#"),
      shiny::actionButton(ns("submit"), "Submit", class = "btn-primary w-100"),
      shiny::actionButton(
        ns("hint"), "Show solution",
        class = "btn-outline-secondary w-100 mt-2"
      )
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      gm_board_card(
        "Puzzle", ns("board"),
        click = ns("board_click"), height = "470px"
      ),
      gm_stack(
        gm_text_card("This puzzle", shiny::uiOutput(ns("progress"))),
        gm_text_card("Feedback", shiny::uiOutput(ns("feedback")))
      )
    )
  )
}

mod_puzzles_server <- function(id, store = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    first <- tryCatch(gambitR::gm_puzzle(seed = 1L), error = function(e) NULL)
    rv <- shiny::reactiveValues(
      puzzle = first,
      position = if (is.null(first)) gambitR::gm_position() else first$position,
      attempt = character(0L),
      selected = NULL,
      note = "Find the best move."
    )

    shiny::observe({
      shiny::updateSelectInput(
        session, "theme",
        choices = c("any", gm_puzzle_themes())
      )
    })

    draw <- function() {
      theme <- input$theme
      theme <- if (is.null(theme) || identical(theme, "any")) NULL else theme
      puzzle <- tryCatch(gambitR::gm_puzzle(theme = theme), error = function(e) NULL)
      if (is.null(puzzle)) {
        rv$note <- "Could not load a puzzle with that theme."
        return(invisible(NULL))
      }
      rv$puzzle <- puzzle
      rv$position <- puzzle$position
      rv$attempt <- character(0L)
      rv$selected <- NULL
      rv$note <- if (length(puzzle$solution) == 1L) {
        "Find the move."
      } else {
        paste0("Find the first of ", length(puzzle$solution), " moves.")
      }
      invisible(NULL)
    }

    submit <- function(san) {
      shiny::req(rv$puzzle)
      solution <- rv$puzzle$solution
      index <- length(rv$attempt) + 1L
      if (index > length(solution)) {
        rv$note <- "The puzzle is already solved."
        return(invisible(NULL))
      }
      if (!identical(gsub("[+#!?]", "", san), gsub("[+#!?]", "", solution[[index]]))) {
        rv$note <- paste0("Not the move. Try again from move ", index, ".")
        rv$attempt <- character(0L)
        rv$position <- rv$puzzle$position
        rv$selected <- NULL
        return(invisible(NULL))
      }
      out <- tryCatch(
        gambitR::gm_move(rv$position, solution[[index]]),
        error = function(e) NULL
      )
      if (is.null(out)) {
        return(invisible(NULL))
      }
      rv$position <- out
      rv$attempt <- c(rv$attempt, solution[[index]])
      rv$selected <- NULL
      # Play the opponent's forced reply straight away.
      if (length(rv$attempt) < length(solution) && length(rv$attempt) %% 2L == 1L) {
        reply <- solution[[length(rv$attempt) + 1L]]
        replied <- tryCatch(gambitR::gm_move(rv$position, reply), error = function(e) NULL)
        if (!is.null(replied)) {
          rv$position <- replied
          rv$attempt <- c(rv$attempt, reply)
        }
      }
      result <- gambitR::gm_check_solution(rv$puzzle, rv$attempt)
      rv$note <- if (isTRUE(result$correct)) {
        "Solved. Draw another puzzle."
      } else {
        "Correct so far. Keep going."
      }
      invisible(NULL)
    }

    shiny::observeEvent(input$new, draw())

    shiny::observeEvent(input$submit, {
      shiny::req(input$san)
      if (nzchar(trimws(input$san))) {
        submit(trimws(input$san))
        shiny::updateTextInput(session, "san", value = "")
      }
    })

    shiny::observeEvent(input$hint, {
      shiny::req(rv$puzzle)
      rv$note <- paste0("Solution: ", paste(rv$puzzle$solution, collapse = " "))
    })

    shiny::observeEvent(input$board_click, {
      shiny::req(rv$position)
      square <- gm_click_square(input$board_click)
      if (is.null(square)) {
        return(invisible(NULL))
      }
      legal <- gambitR::gm_legal_moves(rv$position)
      if (is.null(rv$selected)) {
        if (square %in% legal$from) rv$selected <- square
        return(invisible(NULL))
      }
      san <- gm_resolve_move(rv$position, rv$selected, square)
      if (is.null(san)) {
        rv$selected <- if (square %in% legal$from) square else NULL
        return(invisible(NULL))
      }
      submit(san)
    })

    output$board <- shiny::renderPlot(
      {
        shiny::req(rv$position)
        gm_safe_board(rv$position, highlight = rv$selected)
      },
      res = 96
    )

    output$feedback <- shiny::renderUI({
      tryCatch(
        {
          shiny::req(rv$puzzle)
          shiny::tagList(
            shiny::div(class = "gm-status", rv$note),
            if (length(rv$attempt)) {
              shiny::div(
                class = "gm-meta mt-1",
                paste0("Played: ", paste(rv$attempt, collapse = " "))
              )
            }
          )
        },
        error = function(e) gm_empty("No puzzle loaded.")
      )
    })

    # The solution checker returns machine fields; the panel reads them out in
    # words. Raw `correct / solved_plies / total_plies` is not a user interface.
    output$progress <- shiny::renderUI({
      tryCatch(
        {
          shiny::req(rv$puzzle)
          result <- gambitR::gm_check_solution(rv$puzzle, rv$attempt)
          solved <- as.integer(result$solved_plies)
          total <- as.integer(result$total_plies)
          shiny::tagList(
            shiny::div(
              class = if (isTRUE(result$correct)) "gm-status gm-solved" else "gm-status",
              if (isTRUE(result$correct)) "Solved" else gm_status_text(rv$position)
            ),
            shiny::div(
              class = "gm-meta mt-1",
              paste0(
                solved, " of ", total, " move", if (total == 1L) "" else "s",
                " found  ·  theme ", rv$puzzle$theme,
                "  ·  rating ", rv$puzzle$rating,
                "  ·  ", rv$puzzle$id
              )
            )
          )
        },
        error = function(e) gm_empty("No puzzle loaded.")
      )
    })
  })
}
