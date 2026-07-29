# Module: simulate - batch tournaments between two strategies.

gm_result_labels <- c(
  "1-0" = "White wins", "1/2-1/2" = "Draw", "0-1" = "Black wins"
)

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
      shiny::actionButton(ns("run"), "Run simulation", class = "btn-primary w-100"),
      shiny::div(
        class = "gm-meta mt-3",
        "The engine strategy searches to depth 2; a long batch takes a while."
      )
    ),
    bslib::layout_columns(
      col_widths = c(7, 5),
      gm_stack(
        gm_text_card("Outcomes", shiny::uiOutput(ns("chart_ui"))),
        gm_text_card("Summary", shiny::uiOutput(ns("summary")))
      ),
      gm_text_card(
        "Results",
        shiny::div(class = "gm-table-scroll", shiny::uiOutput(ns("table_ui")))
      )
    )
  )
}

mod_simulate_server <- function(id, store = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    rv <- shiny::reactiveValues(results = NULL, label = NULL)

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
      rv$label <- paste0(input$white, " as White vs ", input$black, " as Black")
      if (!is.null(store) && !is.null(results)) {
        store$simulation <- results
      }
    })

    output$chart_ui <- shiny::renderUI({
      if (is.null(rv$results)) {
        gm_empty("Choose two strategies and press Run simulation.")
      } else {
        gm_chart_output(session$ns("chart"), height = "230px")
      }
    })

    output$summary <- shiny::renderUI({
      if (is.null(rv$results)) {
        return(gm_empty("No games yet."))
      }
      tryCatch(
        {
          results <- rv$results
          n <- nrow(results)
          wins <- sum(results$result == "1-0")
          draws <- sum(results$result == "1/2-1/2")
          losses <- sum(results$result == "0-1")
          # The conventional chess score: a win is 1, a draw a half.
          points <- wins + draws / 2
          shiny::tagList(
            shiny::div(class = "gm-status", rv$label),
            shiny::div(
              class = "gm-meta mt-1",
              paste0(
                n, " game", if (n == 1L) "" else "s", "  ·  White scored ",
                format(points, trim = TRUE), " / ", n,
                "  (", wins, " win", if (wins == 1L) "" else "s", ", ",
                draws, " draw", if (draws == 1L) "" else "s", ", ",
                losses, " loss", if (losses == 1L) "" else "es", ")",
                "  ·  median ", stats::median(results$plies), " plies"
              )
            )
          )
        },
        error = function(e) gm_empty(conditionMessage(e))
      )
    })

    output$table_ui <- shiny::renderUI({
      if (is.null(rv$results)) {
        gm_empty("No games yet.")
      } else {
        shiny::tableOutput(session$ns("table"))
      }
    })

    output$table <- shiny::renderTable(
      {
        shiny::req(rv$results)
        tryCatch(
          {
            results <- rv$results
            data.frame(
              Game = as.integer(results$game),
              Result = unname(gm_result_labels[results$result]),
              Plies = as.integer(results$plies),
              Termination = results$termination,
              stringsAsFactors = FALSE
            )
          },
          error = function(e) NULL
        )
      },
      striped = TRUE, hover = TRUE, spacing = "xs", width = "100%",
      align = "llrl"
    )

    chart <- function() {
      if (is.null(rv$results)) {
        return(NULL)
      }
      tryCatch(
        {
          levels <- names(gm_result_labels)
          counts <- as.data.frame(
            table(factor(rv$results$result, levels = levels)),
            stringsAsFactors = FALSE
          )
          names(counts) <- c("result", "games")
          counts$label <- factor(
            unname(gm_result_labels[counts$result]),
            levels = rev(unname(gm_result_labels))
          )
          fills <- stats::setNames(
            c("#5E2C8E", "#B0B7BF", "#3D3733"), unname(gm_result_labels)
          )
          # No data labels on the bars. The axis already carries whole-game
          # counts and the Summary card spells the tally out, so a label would
          # be a third encoding of the same number - and ggplotly re-lays text
          # out with its own metrics, which either clipped it at the panel edge
          # or left it half off the end of its bar.
          ggplot2::ggplot(counts, ggplot2::aes(x = .data$games, y = .data$label)) +
            ggplot2::geom_col(
              ggplot2::aes(fill = .data$label),
              width = 0.62, show.legend = FALSE
            ) +
            ggplot2::scale_fill_manual(values = fills, guide = "none") +
            ggplot2::scale_x_continuous(
              expand = ggplot2::expansion(mult = c(0, 0.08)),
              breaks = function(r) unique(floor(pretty(seq(0, max(1, r[2])))))
            ) +
            ggplot2::labs(x = "Games", y = NULL) +
            ggplot2::theme_minimal(base_size = 12) +
            ggplot2::theme(
              panel.grid.major.y = ggplot2::element_blank(),
              panel.grid.minor = ggplot2::element_blank(),
              panel.grid.major.x = ggplot2::element_line(
                colour = "#E8E4DF", linewidth = 0.3
              ),
              axis.title = ggplot2::element_text(colour = "#7A736C", size = 10),
              axis.text = ggplot2::element_text(colour = "#332F2B"),
              plot.margin = ggplot2::margin(8, 14, 4, 4)
            )
        },
        error = function(e) NULL
      )
    }

    output$chart <- gm_render_chart(chart)
  })
}
