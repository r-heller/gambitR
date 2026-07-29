# Negamax search with alpha-beta pruning.

.GM_MATE_SCORE <- 100000

#' Search for the best move
#'
#' Minimax search with alpha-beta pruning to a fixed depth, driven by
#' [gm_evaluate()]. This is the native R engine used for play and simulation.
#'
#' Moves are ordered captures first, most valuable victim before least
#' valuable attacker, which is what makes the alpha-beta cut-offs pay. Forced
#' mates are scored near `100000` and discounted by the distance to mate, so a
#' mate in one is preferred to a mate in three.
#'
#' @param position A [gm_position] object.
#' @param depth Search depth in plies. Default `3`.
#' @param engine Backend: `"native"` (default, pure R minimax) or `"uci"` to
#'   delegate to an external 'UCI' engine via [gm_uci_bestmove()].
#' @param verbose If `TRUE` (default), report search progress.
#' @param call The execution environment, for error reporting. Experts only.
#' @return A [tibble::tibble()] with columns `san` (best move), `score`
#'   (centipawns, White's perspective), `depth` (integer) and `nodes`
#'   (integer, nodes searched). One row.
#' @export
#' @family analysis
#' @examples
#' \donttest{
#' gm_bestmove(gm_position(), depth = 2)
#' }
gm_bestmove <- function(position, depth = 3L, engine = c("native", "uci"),
                        verbose = TRUE, call = rlang::caller_env()) {
  engine <- rlang::arg_match(engine)
  if (!is_gm_position(position)) {
    cli::cli_abort("{.arg position} must be a {.cls gm_position} object.", call = call)
  }
  if (!is.numeric(depth) || length(depth) != 1L || is.na(depth) || depth < 1) {
    cli::cli_abort("{.arg depth} must be a single positive number.", call = call)
  }
  depth <- as.integer(depth)
  if (engine == "uci") {
    info <- .gm_uci_query(position, verbose = verbose, call = call)
    return(tibble::tibble(
      san = info$san, score = info$score,
      depth = info$depth, nodes = info$nodes
    ))
  }
  st <- .gm_state(position)
  mv <- .gm_gen_legal(st)
  n <- length(mv$from)
  if (n == 0L) {
    return(tibble::tibble(
      san = NA_character_, score = .gm_eval_state(st),
      depth = depth, nodes = 0L
    ))
  }
  mv <- .gm_order_moves(mv)
  counter <- new.env(parent = emptyenv())
  counter$nodes <- 0L
  weights <- .gm_default_weights()
  best <- -Inf
  best_i <- 1L
  alpha <- -Inf
  if (verbose) {
    cli::cli_progress_bar("Searching", total = n, .envir = rlang::current_env())
  }
  for (i in seq_len(n)) {
    score <- -.gm_negamax(
      .gm_make(st, mv, i), depth - 1L, -Inf, -alpha, 1L, counter, weights
    )
    if (score > best) {
      best <- score
      best_i <- i
    }
    if (score > alpha) alpha <- score
    if (verbose) cli::cli_progress_update(.envir = rlang::current_env())
  }
  san <- .gm_san_all(st, lapply(mv, function(x) x[best_i]))
  tibble::tibble(
    san = san,
    score = if (st$turn == 1L) best else -best,
    depth = depth,
    nodes = counter$nodes
  )
}

# Negamax: the returned score is always from the point of view of the side to
# move in `st`.
#' @noRd
.gm_negamax <- function(st, depth, alpha, beta, ply, counter, weights) {
  counter$nodes <- counter$nodes + 1L
  mv <- .gm_gen_legal(st)
  n <- length(mv$from)
  if (n == 0L) {
    return(if (.gm_in_check(st)) -(.GM_MATE_SCORE - ply) else 0)
  }
  if (depth <= 0L) {
    score <- .gm_eval_state(st, weights)
    return(if (st$turn == 1L) score else -score)
  }
  mv <- .gm_order_moves(mv)
  best <- -Inf
  for (i in seq_len(n)) {
    score <- -.gm_negamax(
      .gm_make(st, mv, i), depth - 1L, -beta, -alpha, ply + 1L, counter, weights
    )
    if (score > best) best <- score
    if (score > alpha) alpha <- score
    if (alpha >= beta) break
  }
  best
}

# Captures first, ordered by most valuable victim / least valuable attacker,
# then promotions, then quiet moves.
#' @noRd
.gm_order_moves <- function(mv) {
  n <- length(mv$from)
  if (n < 2L) {
    return(mv)
  }
  victim <- .GM_PIECE_VALUE[((mv$capture - 1L) %% 6L) + 1L]
  victim[mv$capture == 0L] <- 0
  attacker <- .GM_PIECE_VALUE[((mv$piece - 1L) %% 6L) + 1L]
  score <- ifelse(mv$capture == 0L, 0, 10000 + 10 * victim - attacker)
  score <- score + ifelse(mv$flag == 4L, 900, 0)
  ord <- order(score, decreasing = TRUE)
  lapply(mv, function(x) x[ord])
}
