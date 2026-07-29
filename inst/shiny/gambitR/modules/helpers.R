# Shared helpers for the gambitR Shiny modules.
# No library() calls anywhere: everything is namespace-qualified.

gm_accent <- "#5E2C8E"

gm_strategies <- c("random", "engine")

# shinyWidgets and plotly are optional. Every use goes through one of these
# helpers so the app degrades to base shiny when they are not installed.
gm_have <- function(pkg) {
  requireNamespace(pkg, quietly = TRUE)
}

# base R gained `%||%` in 4.4.0; the package supports 4.1.0 upwards.
`%|OR|%` <- function(x, y) if (is.null(x)) y else x

# Mirrors gambitR's own check without reaching into the namespace.
gm_uci_available <- function() {
  gm_have("processx") && nzchar(Sys.which("stockfish"))
}

gm_picker <- function(input_id, label, choices, selected = NULL, multiple = FALSE) {
  if (gm_have("shinyWidgets")) {
    shinyWidgets::pickerInput(
      input_id, label,
      choices = choices, selected = selected, multiple = multiple
    )
  } else {
    shiny::selectInput(
      input_id, label,
      choices = choices, selected = selected, multiple = multiple
    )
  }
}

gm_toggle <- function(input_id, label, value = FALSE) {
  if (gm_have("shinyWidgets")) {
    shinyWidgets::materialSwitch(input_id, label, value = value, status = "primary")
  } else {
    shiny::checkboxInput(input_id, label, value = value)
  }
}

# Translate a click on a board drawn by gambitR::gm_plot_board() back into a
# square name, honouring the board orientation.
gm_click_square <- function(click, flip = FALSE) {
  if (is.null(click) || is.null(click$x) || is.null(click$y)) {
    return(NULL)
  }
  x <- round(click$x)
  y <- round(click$y)
  if (is.na(x) || is.na(y) || x < 1L || x > 8L || y < 1L || y > 8L) {
    return(NULL)
  }
  column <- if (flip) 9L - x else x
  rank <- if (flip) 9L - y else y
  paste0(letters[column], rank)
}

# Resolve a from/to square pair against the legal moves of a position,
# promoting to a queen when a promotion is required.
gm_resolve_move <- function(position, from, to) {
  moves <- gambitR::gm_legal_moves(position)
  hit <- moves[moves$from == from & moves$to == to, , drop = FALSE]
  if (nrow(hit) == 0L) {
    return(NULL)
  }
  queen <- hit[!is.na(hit$promotion) & hit$promotion == "Q", , drop = FALSE]
  if (nrow(queen) > 0L) queen$san[[1L]] else hit$san[[1L]]
}

gm_movetext <- function(moves) {
  if (!length(moves)) {
    return("(no moves yet)")
  }
  numbered <- vapply(seq_along(moves), function(i) {
    if (i %% 2L == 1L) paste0((i + 1L) %/% 2L, ". ", moves[[i]]) else moves[[i]]
  }, character(1L))
  paste(strwrap(paste(numbered, collapse = " "), width = 60L), collapse = "\n")
}

gm_status_text <- function(position) {
  status <- gambitR::gm_status(position)
  side <- if (position$turn == "w") "White" else "Black"
  winner <- if (position$turn == "w") "Black" else "White"
  switch(status,
    checkmate = paste0("Checkmate: ", winner, " wins"),
    stalemate = "Stalemate: draw",
    check = paste0(side, " to move (in check)"),
    paste0(side, " to move")
  )
}

gm_is_over <- function(position) {
  gambitR::gm_status(position) %in% c("checkmate", "stalemate")
}

# Every renderPlot in the app funnels through here so a transient bad state
# shows an empty panel instead of an error. The app carries its own status
# chrome, so the plot's own title, subtitle and FEN caption are dropped: at
# panel size they are illegible and they duplicate the surrounding cards.
gm_safe_board <- function(position, highlight = NULL, flip = FALSE) {
  tryCatch(
    gambitR::gm_plot_board(position, highlight = highlight, flip = flip) +
      ggplot2::labs(title = NULL, subtitle = NULL) +
      ggplot2::theme(plot.margin = ggplot2::margin(2, 2, 2, 2)),
    error = function(e) NULL
  )
}

# The evaluation curve carries its own title, which would repeat the card
# header it sits under; the subtitle keeps the unit.
gm_safe_eval <- function(game) {
  tryCatch(
    gambitR::gm_plot_eval(game) + ggplot2::labs(title = NULL),
    error = function(e) NULL
  )
}

# A board panel: square, click-aware and hugging the plot. All five boards in
# the app go through here so they are the same object on every tab.
gm_board_output <- function(input_id, click = NULL, height = "520px") {
  shiny::plotOutput(input_id, click = click, height = height)
}

# `...` takes anything that belongs under the board (a ply bar, a caption).
# It sits before the optional arguments so that extra content can never be
# matched positionally against `click`.
gm_board_card <- function(title, input_id, ..., click = NULL, height = "520px") {
  bslib::card(
    class = "gm-board-card",
    fill = FALSE,
    bslib::card_header(title),
    bslib::card_body(
      gm_board_output(input_id, click = click, height = height),
      ...
    )
  )
}

# Cards in this app hold either a plot that should fill or a short block of
# text that should not stretch. Text cards opt out of filling.
gm_text_card <- function(title, ..., min_height = NULL) {
  bslib::card(
    fill = FALSE,
    min_height = min_height,
    bslib::card_header(title),
    bslib::card_body(...)
  )
}

# A column of cards that hug their content and stack from the top, instead of
# being stretched to equal heights by the surrounding grid.
gm_stack <- function(...) {
  shiny::div(class = "gm-stack", ...)
}

# Placeholder shown where a panel would otherwise render blank.
gm_empty <- function(text) {
  shiny::div(class = "gm-empty", text)
}

# plotly is optional: the chart is interactive when it is installed and a
# plain ggplot otherwise.
gm_chart_output <- function(input_id, height = "300px") {
  if (gm_have("plotly")) {
    plotly::plotlyOutput(input_id, height = height)
  } else {
    shiny::plotOutput(input_id, height = height)
  }
}

gm_render_chart <- function(build) {
  if (gm_have("plotly")) {
    plotly::renderPlotly({
      plot <- build()
      if (is.null(plot)) {
        return(NULL)
      }
      # Two ggplotly warts to work around: it re-derives the legend from the
      # fill scale and ignores `show.legend`, so the legend has to be switched
      # off on the plotly object; and a custom `tooltip` on a bar chart makes
      # it write a `mode` attribute that bar traces reject, so the hover text
      # is left at plotly's own default. The modebar otherwise floats straight
      # through the plot.
      plotly::config(
        plotly::layout(plotly::ggplotly(plot), showlegend = FALSE),
        displayModeBar = FALSE
      )
    })
  } else {
    shiny::renderPlot(build(), res = 96)
  }
}

# The bundled puzzle set is a plain rds, so the themes can be listed without
# reaching into the package namespace.
gm_puzzle_themes <- function() {
  path <- system.file("extdata", "puzzles.rds", package = "gambitR")
  if (!nzchar(path) || !file.exists(path)) {
    return(character(0L))
  }
  tryCatch(sort(unique(readRDS(path)$theme)), error = function(e) character(0L))
}

gm_game_from_moves <- function(moves, positions, result = "*") {
  game <- gambitR::gm_read_pgn("*", text = TRUE)
  game$moves <- moves
  game$positions <- positions
  game$result <- result
  game
}
