# A minimal stand-in for a 'UCI' engine, so the client half of the protocol
# can be exercised without depending on an external binary being installed.
gm_fake_engine <- function(envir = parent.frame()) {
  testthat::skip_on_os("windows")
  testthat::skip_if_not_installed("processx")
  testthat::skip_if_not_installed("withr")
  path <- withr::local_tempfile(fileext = ".sh", .local_envir = envir)
  writeLines(c(
    "#!/bin/sh",
    "while IFS= read -r line; do",
    "  case \"$line\" in",
    "    uci) echo 'id name fakefish'; echo 'uciok' ;;",
    "    isready) echo 'readyok' ;;",
    "    go*) echo 'info depth 4 nodes 4242 score cp 25 pv e2e4 e7e5';",
    "         echo 'bestmove e2e4 ponder e7e5' ;;",
    "    quit) exit 0 ;;",
    "  esac",
    "done"
  ), path)
  Sys.chmod(path, "0755")
  path
}
