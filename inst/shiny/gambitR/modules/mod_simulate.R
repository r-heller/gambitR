# Module: simulate - batch tournaments between two strategies.

mod_simulate_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 280,
      shiny::helpText("Pit two strategies against each other and summarise the outcomes."),
      gm_picker(ns("white"), "White", gm_strategies, "random"),
      gm_picker(ns("black"), "Black", gm_strategies, "random"),
      shiny::numericInput(ns("n"), "Games", value = 5L, min = 1L, max = 200L, step = 1L),
      shiny::numericInput(
        ns("max_moves"), "Maximum full moves",
        value = 40L, min = 1L, max = 200L, step = 1L
      ),
      shiny::actionButton(ns("run"), "Run simulation", class = "btn-primary w-100")
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(
        bslib::card_header("Outcomes"),
        gm_chart_output(ns("chart"))
      ),
      bslib::card(
        bslib::card_header("Results"),
        shiny::tableOutput(ns("table"))
      )
    )
  )
}

mod_simulate_server <- function(id, store = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(results = NULL)

    shiny::observeEvent(input$run, {
      shiny::req(input$n, input$max_moves)
      results <- tryCatch(
        gambitR::gm_simulate(
          white = input$white, black = input$black,
          n = as.integer(input$n), max_moves = as.integer(input$max_moves),
          verbose = FALSE
        ),
        error = function(e) NULL
      )
      rv$results <- results
      if (!is.null(store) && !is.null(results)) {
        store$simulation <- results
      }
    })

    output$table <- shiny::renderTable({
      shiny::req(rv$results)
      tryCatch(
        {
          results <- rv$results
          results$game <- as.integer(results$game)
          results$plies <- as.integer(results$plies)
          results
        },
        error = function(e) NULL
      )
    })

    chart <- function() {
      if (is.null(rv$results)) {
        return(NULL)
      }
      tryCatch(
        {
          counts <- as.data.frame(
            table(factor(rv$results$result, levels = c("1-0", "1/2-1/2", "0-1"))),
            stringsAsFactors = FALSE
          )
          names(counts) <- c("result", "games")
          ggplot2::ggplot(counts, ggplot2::aes(x = .data$result, y = .data$games)) +
            ggplot2::geom_col(fill = gm_accent, width = 0.6) +
            ggplot2::geom_text(
              ggplot2::aes(label = .data$games),
              vjust = -0.4, colour = "grey30"
            ) +
            ggplot2::labs(
              title = paste0(input$white, " (White) versus ", input$black, " (Black)"),
              x = NULL, y = "Games"
            ) +
            ggplot2::theme_minimal() +
            ggplot2::theme(
              plot.title = ggplot2::element_text(face = "bold", colour = gm_accent),
              panel.grid.major.x = ggplot2::element_blank()
            )
        },
        error = function(e) NULL
      )
    }

    output$chart <- gm_render_chart(chart)
  })
}
