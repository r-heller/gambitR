.GM_RESULTS <- c("1-0", "0-1", "1/2-1/2", "*")

.GM_PGN_TAG_ORDER <- c(
  "Event", "Site", "Date", "Round", "White", "Black", "Result"
)

#' Read a game from 'PGN'
#'
#' Parse Portable Game Notation into a game object: header tags plus the
#' sequence of moves and resulting positions.
#'
#' Comments (`{...}` and `;` to end of line), numeric annotation glyphs
#' (`$1`), move numbers and recursive variations (`(...)`) are stripped, and
#' the remaining mainline tokens are replayed through [gm_move()], so an
#' illegal or ambiguous move is reported where it occurs. A `FEN` tag is
#' honoured as the starting position.
#'
#' @param file A path to a `.pgn` file, or a single character string of 'PGN'
#'   text when `text = TRUE`.
#' @param text If `TRUE`, treat `file` as literal 'PGN' text rather than a path.
#' @param call The execution environment, for error reporting. Experts only.
#' @return A [gm_game] object.
#' @export
#' @family io
#' @examples
#' pgn <- "1. e4 e5 2. Nf3 Nc6 *"
#' gm_read_pgn(pgn, text = TRUE)
gm_read_pgn <- function(file, text = FALSE, call = rlang::caller_env()) {
  if (!is.logical(text) || length(text) != 1L || is.na(text)) {
    cli::cli_abort("{.arg text} must be {.code TRUE} or {.code FALSE}.", call = call)
  }
  if (!is.character(file) || length(file) != 1L || is.na(file)) {
    cli::cli_abort("{.arg file} must be a single non-NA string.", call = call)
  }
  if (text) {
    lines <- strsplit(file, "\r?\n")[[1L]]
  } else {
    if (!file.exists(file)) {
      cli::cli_abort("Cannot find the 'PGN' file {.path {file}}.", call = call)
    }
    lines <- readLines(file, warn = FALSE)
  }
  tags <- .gm_parse_tags(lines)
  # `;` comments run to the end of their own line, so they must go before the
  # movetext is folded into a single string.
  body <- sub(";.*$", "", lines[!grepl("^\\s*\\[", lines)])
  tokens <- .gm_tokenise_movetext(paste(body, collapse = " "))
  result <- tags[["Result"]] %||% "*"
  if (length(tokens) && tokens[length(tokens)] %in% .GM_RESULTS) {
    result <- tokens[length(tokens)]
    tokens <- tokens[-length(tokens)]
  }
  tokens <- tokens[!tokens %in% .GM_RESULTS]
  start <- if (!is.null(tags[["FEN"]])) {
    gm_read_fen(tags[["FEN"]], call = call)
  } else {
    gm_position(call = call)
  }
  positions <- vector("list", length(tokens) + 1L)
  positions[[1L]] <- start
  moves <- character(length(tokens))
  current <- start
  for (i in seq_along(tokens)) {
    current <- withCallingHandlers(
      gm_move(current, tokens[[i]], call = call),
      error = function(cnd) {
        cli::cli_abort(
          "Could not replay move {i} ({.val {tokens[[i]]}}) of the 'PGN'.",
          parent = cnd, call = call
        )
      }
    )
    moves[[i]] <- tokens[[i]]
    positions[[i + 1L]] <- current
  }
  if (!is.null(tags[["Result"]])) tags[["Result"]] <- result
  new_gm_game(moves = moves, positions = positions, tags = tags, result = result)
}

#' @noRd
.gm_parse_tags <- function(lines) {
  hits <- grep("^\\s*\\[[A-Za-z0-9_]+\\s+\"", lines, value = TRUE)
  if (!length(hits)) {
    return(list())
  }
  keys <- sub("^\\s*\\[([A-Za-z0-9_]+)\\s+\".*$", "\\1", hits)
  values <- sub("^\\s*\\[[A-Za-z0-9_]+\\s+\"(.*)\"\\s*\\]\\s*$", "\\1", hits)
  out <- as.list(values)
  names(out) <- keys
  out[!duplicated(keys)]
}

# Reduce movetext to a plain vector of SAN tokens plus a trailing result.
#' @noRd
.gm_tokenise_movetext <- function(movetext) {
  txt <- gsub(";[^\n]*", " ", movetext)
  txt <- gsub("\\{[^}]*\\}", " ", txt)
  txt <- .gm_strip_variations(txt)
  txt <- gsub("\\$[0-9]+", " ", txt)
  txt <- gsub("[0-9]+\\s*\\.(\\.\\.)?", " ", txt)
  tokens <- strsplit(trimws(txt), "[[:space:]]+")[[1L]]
  tokens <- tokens[nzchar(tokens)]
  tokens[!tokens %in% c("--", "...")]
}

#' @noRd
.gm_strip_variations <- function(txt) {
  chars <- strsplit(txt, "", fixed = TRUE)[[1L]]
  keep <- logical(length(chars))
  depth <- 0L
  for (i in seq_along(chars)) {
    ch <- chars[[i]]
    if (ch == "(") {
      depth <- depth + 1L
    } else if (ch == ")") {
      depth <- max(0L, depth - 1L)
    } else {
      keep[[i]] <- depth == 0L
    }
  }
  paste(chars[keep], collapse = "")
}

#' Write a game to 'PGN'
#'
#' @param game A [gm_game] object.
#' @param path Optional output path. If `NULL` (default), the 'PGN' string is
#'   returned invisibly instead of being written.
#' @param overwrite If `FALSE` (default), error rather than overwrite `path`.
#' @return The 'PGN' string, invisibly. Called for its side effect when `path`
#'   is supplied.
#' @export
#' @family io
#' @examples
#' cat(gm_write_pgn(gm_read_pgn("1. e4 e5 *", text = TRUE)))
gm_write_pgn <- function(game, path = NULL, overwrite = FALSE) {
  if (!is_gm_game(game)) {
    cli::cli_abort("{.arg game} must be a {.cls gm_game} object.")
  }
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    cli::cli_abort("{.arg overwrite} must be {.code TRUE} or {.code FALSE}.")
  }
  tags <- .gm_pgn_tags(game)
  header <- paste0("[", names(tags), " \"", unlist(tags, use.names = FALSE), "\"]")
  body <- .gm_pgn_movetext(game$moves, game$result)
  pgn <- paste0(paste(c(header, "", body, ""), collapse = "\n"))
  if (!is.null(path)) {
    if (!is.character(path) || length(path) != 1L || is.na(path)) {
      cli::cli_abort("{.arg path} must be a single non-NA string.")
    }
    if (file.exists(path) && !overwrite) {
      cli::cli_abort(c(
        "{.path {path}} already exists.",
        "i" = "Pass {.code overwrite = TRUE} to replace it."
      ))
    }
    writeLines(pgn, path)
  }
  invisible(pgn)
}

# The seven tag roster, in standard order, followed by any extra tags.
#' @noRd
.gm_pgn_tags <- function(game) {
  defaults <- list(
    Event = "gambitR game", Site = "?", Date = "????.??.??",
    Round = "?", White = "?", Black = "?", Result = game$result
  )
  supplied <- game$tags %||% list()
  for (nm in names(defaults)) {
    if (!is.null(supplied[[nm]]) && nzchar(supplied[[nm]])) {
      defaults[[nm]] <- supplied[[nm]]
    }
  }
  defaults[["Result"]] <- game$result
  extra <- supplied[setdiff(names(supplied), .GM_PGN_TAG_ORDER)]
  c(defaults, extra)
}

# Movetext with move numbers, wrapped at 80 columns as the standard asks.
#' @noRd
.gm_pgn_movetext <- function(moves, result, width = 80L) {
  parts <- character(0L)
  for (i in seq_along(moves)) {
    if (i %% 2L == 1L) {
      parts <- c(parts, paste0((i + 1L) %/% 2L, ". ", moves[[i]]))
    } else {
      parts <- c(parts, moves[[i]])
    }
  }
  parts <- c(parts, result)
  lines <- character(0L)
  current <- ""
  for (part in parts) {
    if (!nzchar(current)) {
      current <- part
    } else if (nchar(current) + nchar(part) + 1L <= width) {
      current <- paste(current, part)
    } else {
      lines <- c(lines, current)
      current <- part
    }
  }
  if (nzchar(current)) lines <- c(lines, current)
  lines
}
