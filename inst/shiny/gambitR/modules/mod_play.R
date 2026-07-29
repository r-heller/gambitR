# Module: play - a game against the native engine.

mod_play_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 280,
      shiny::helpText(
        "Click a piece and then its destination, or type a move in algebraic",
        "notation."
      ),
      gm_picker(ns("side"), "Play as", c("White", "Black"), "White"),
      shiny::sliderInput(
        ns("depth"), "Engine depth",
        min = 1L, max = 3L, value = 2L, step = 1L, ticks = FALSE
      ),
      gm_toggle(ns("flip"), "Flip board"),
      shiny::textInput(ns("san"), "Move", placeholder = "e4"),
      shiny::actionButton(ns("submit"), "Play move", class = "btn-primary w-100"),
      shiny::hr(),
      shiny::actionButton(ns("new"), "New game", class = "btn-outline-secondary w-100"),
      shiny::actionButton(
        ns("resign"), "Resign",
        class = "btn-outline-secondary w-100 mt-2"
      )
    ),
    bslib::layout_columns(
      col_widths = c(7, 5),
      gm_board_card(
        "Board", ns("board"),
        click = ns("board_click"), height = "560px"
      ),
      gm_stack(
        gm_text_card("Status", shiny::uiOutput(ns("status"))),
        gm_text_card("Moves", shiny::uiOutput(ns("moves"))),
        gm_text_card("Engine", shiny::uiOutput(ns("engine")))
      )
    )
  )
}

mod_play_server <- function(id, store = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(
      position = gambitR::gm_position(),
      moves = character(0L),
      positions = list(gambitR::gm_position()),
      selected = NULL,
      note = "New game. White to move.",
      result = "*"
    )

    human <- shiny::reactive({
      if (identical(input$side, "Black")) "b" else "w"
    })

    reset <- function() {
      start <- gambitR::gm_position()
      rv$position <- start
      rv$moves <- character(0L)
      rv$positions <- list(start)
      rv$selected <- NULL
      rv$result <- "*"
      rv$note <- "New game. White to move."
    }

    apply_move <- function(san) {
      out <- tryCatch(gambitR::gm_move(rv$position, san), error = function(e) e)
      if (inherits(out, "error")) {
        rv$note <- conditionMessage(out)
        return(FALSE)
      }
      rv$position <- out
      rv$moves <- c(rv$moves, san)
      rv$positions <- c(rv$positions, list(out))
      rv$selected <- NULL
      TRUE
    }

    finish <- function() {
      if (rv$result == "*" && gm_is_over(rv$position)) {
        rv$result <- if (gambitR::gm_status(rv$position) == "checkmate") {
          if (rv$position$turn == "w") "0-1" else "1-0"
        } else {
          "1/2-1/2"
        }
      }
    }

    engine_reply <- function() {
      if (rv$result != "*" || gm_is_over(rv$position)) {
        return(invisible(NULL))
      }
      if (identical(rv$position$turn, human())) {
        return(invisible(NULL))
      }
      depth <- input$depth
      if (is.null(depth)) depth <- 2L
      best <- tryCatch(
        gambitR::gm_bestmove(rv$position, depth = depth, verbose = FALSE),
        error = function(e) NULL
      )
      if (is.null(best) || is.na(best$san)) {
        return(invisible(NULL))
      }
      apply_move(best$san)
      rv$note <- paste0(
        "Engine played ", best$san, " (", round(best$score), " cp, ",
        format(best$nodes, big.mark = ","), " nodes searched)."
      )
      invisible(NULL)
    }

    shiny::observeEvent(input$new, {
      reset()
      engine_reply()
      finish()
    })

    shiny::observeEvent(input$resign, {
      if (rv$result == "*") {
        rv$result <- if (identical(human(), "w")) "0-1" else "1-0"
        rv$note <- paste0("Resigned. Result ", rv$result, ".")
      }
    })

    shiny::observeEvent(input$side, {
      reset()
      engine_reply()
      finish()
    })

    shiny::observeEvent(input$submit, {
      shiny::req(input$san)
      if (!nzchar(trimws(input$san))) {
        return(invisible(NULL))
      }
      if (rv$result != "*" || gm_is_over(rv$position)) {
        rv$note <- "The game is over. Start a new one."
        return(invisible(NULL))
      }
      if (apply_move(trimws(input$san))) {
        shiny::updateTextInput(session, "san", value = "")
        rv$note <- paste0("You played ", rv$moves[[length(rv$moves)]], ".")
        finish()
        engine_reply()
        finish()
      }
    })

    shiny::observeEvent(input$board_click, {
      if (rv$result != "*" || gm_is_over(rv$position)) {
        return(invisible(NULL))
      }
      if (!identical(rv$position$turn, human())) {
        return(invisible(NULL))
      }
      square <- gm_click_square(input$board_click, isTRUE(input$flip))
      if (is.null(square)) {
        return(invisible(NULL))
      }
      legal <- gambitR::gm_legal_moves(rv$position)
      if (is.null(rv$selected)) {
        if (square %in% legal$from) {
          rv$selected <- square
          rv$note <- paste0("Selected ", square, ".")
        }
        return(invisible(NULL))
      }
      san <- gm_resolve_move(rv$position, rv$selected, square)
      if (is.null(san)) {
        rv$selected <- if (square %in% legal$from) square else NULL
        return(invisible(NULL))
      }
      if (apply_move(san)) {
        rv$note <- paste0("You played ", san, ".")
        finish()
        engine_reply()
        finish()
      }
    })

    # Publish the running game so the Analyse and Study tabs can pick it up.
    shiny::observe({
      if (!is.null(store)) {
        store$game <- gm_game_from_moves(rv$moves, rv$positions, rv$result)
      }
    })

    last_move_squares <- function() {
      n <- length(rv$moves)
      if (n == 0L) {
        return(NULL)
      }
      before <- rv$positions[[n]]
      legal <- gambitR::gm_legal_moves(before)
      hit <- legal[legal$san == rv$moves[[n]], , drop = FALSE]
      if (nrow(hit)) c(hit$from[[1L]], hit$to[[1L]]) else NULL
    }

    output$board <- shiny::renderPlot(
      {
        shiny::req(rv$position)
        gm_safe_board(
          rv$position,
          highlight = c(rv$selected, last_move_squares()),
          flip = isTRUE(input$flip)
        )
      },
      res = 96
    )

    output$status <- shiny::renderUI({
      shiny::req(rv$position)
      text <- tryCatch(
        if (rv$result != "*") {
          paste0("Game over — ", rv$result)
        } else {
          gm_status_text(rv$position)
        },
        error = function(e) "-"
      )
      shiny::tagList(
        shiny::div(class = "gm-status", text),
        shiny::div(
          class = "gm-meta mt-1",
          paste0(
            "Move ", rv$position$fullmove, " · ",
            length(rv$moves), " half-move", if (length(rv$moves) == 1L) "" else "s",
            " played"
          )
        )
      )
    })

    output$moves <- shiny::renderUI({
      if (!length(rv$moves)) {
        return(gm_empty("No moves yet — play e4 or click a piece."))
      }
      shiny::tags$pre(
        class = "gm-scroll",
        tryCatch(gm_movetext(rv$moves), error = function(e) "")
      )
    })

    output$engine <- shiny::renderUI({
      shiny::tags$pre(tryCatch(rv$note, error = function(e) ""))
    })
  })
}
