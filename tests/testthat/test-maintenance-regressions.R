test_that('counts fail before coercion or search', {
  for (bad in list(Inf, -Inf, NA_real_, 1.5, .Machine$integer.max + 1)) {
    expect_error(gm_bestmove(gm_position(), depth=bad, verbose=FALSE), 'whole number')
    expect_error(gm_play(max_moves=bad, verbose=FALSE), 'whole number')
    expect_error(gm_simulate(n=bad, verbose=FALSE), 'whole number')
    expect_error(gm_puzzle(seed=bad), 'whole number')
  }
})

test_that('repetition ignores unavailable and pinned en-passant captures', {
  with_ep <- gm_move(gm_position(), 'e4')
  without <- with_ep; without$ep <- NA_character_
  expect_identical(.gm_repetition_key(with_ep), .gm_repetition_key(without))
  legal <- gm_read_fen('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1')
  without <- legal; without$ep <- NA_character_
  expect_false(identical(.gm_repetition_key(legal), .gm_repetition_key(without)))
  pinned <- gm_read_fen('k3r3/8/8/3pP3/8/8/8/4K3 w - d6 0 1')
  without <- pinned; without$ep <- NA_character_
  expect_identical(.gm_repetition_key(pinned), .gm_repetition_key(without))
  # Start after e4, repeat the position twice through a legal knight cycle.
  white_moves <- rep(c('Nf3','Ng1'), 2); black_moves <- rep(c('Nf6','Ng8'),2)
  wi <- 0L; bi <- 0L
  g <- gm_play(position=with_ep, white=function(p) {wi <<- wi+1L;white_moves[wi]},
               black=function(p) {bi <<- bi+1L;black_moves[bi]}, max_moves=4,verbose=FALSE)
  expect_identical(g$tags$Termination,'threefold')
  expect_length(g$moves,8L)
})

test_that('seeded puzzle selection preserves caller RNG even on error', {
  set.seed(71); before <- .Random.seed
  a <- gm_puzzle(seed=42); b <- gm_puzzle(seed=42)
  expect_identical(a,b); expect_identical(.Random.seed,before)
  expect_error(gm_puzzle(id='missing-id',seed=42),'No puzzle')
  expect_identical(.Random.seed,before)
  rm('.Random.seed',envir=.GlobalEnv)
  gm_puzzle(seed=42)
  expect_false(exists('.Random.seed',envir=.GlobalEnv,inherits=FALSE))
})

test_that('UCI requests carry both requested depth and bounded search time', {
  transcript <- tempfile()
  on.exit(unlink(transcript))
  engine <- gm_fake_engine(transcript=transcript)
  info <- .gm_uci_query(gm_position(),engine_path=engine,movetime=100,depth=2,verbose=FALSE)
  expect_equal(info$san,'e4')
  expect_true(any(readLines(transcript)=='go movetime 100 depth 2'))
  local_mocked_bindings(.gm_uci_query=function(position,verbose,call,depth) {
    expect_identical(depth,2L)
    list(san='e4',score=25,depth=depth,nodes=1L)
  })
  expect_equal(gm_bestmove(gm_position(),depth=2,engine='uci',verbose=FALSE)$depth,2L)
})
