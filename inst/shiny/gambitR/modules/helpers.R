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
    checkmate = paste0("Checkmate — ", winner, " wins"),
    stalemate = "Stalemate — draw",
    check = paste0(side, " to move (in check)"),
    paste0(side, " to move")
  )
}

gm_is_over <- function(position) {
  gambitR::gm_status(position) %in% c("checkmate", "stalemate")
}

# Every renderPlot in the app funnels through here so a transient bad state
# shows an empty panel instead of an error.
gm_safe_board <- function(position, highlight = NULL, flip = FALSE) {
  tryCatch(
    gambitR::gm_plot_board(position, highlight = highlight, flip = flip),
    error = function(e) NULL
  )
}

# plotly is optional: the chart is interactive when it is installed and a
# plain ggplot otherwise.
gm_chart_output <- function(input_id, height = "320px") {
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
      if (is.null(plot)) NULL else plotly::ggplotly(plot)
    })
  } else {
    shiny::renderPlot(build())
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
