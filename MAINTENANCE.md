# Maintenance record — 30 October 2026

## Purpose and acceptance criteria

Native R chess play, analysis and study, with an optional external UCI
engine.

The current milestone requires correct supported rules,
bounded/validated inputs, meaningful failure-path regressions, an
installable source package, and a working local app. Original checkouts
and unrelated work are preserved in isolated review branches. No
release, push or deployment is implied by this local record.

## Evidence-led findings and repairs

- High: `R/play.R` included an en-passant target in repetition identity
  even when no legal capture existed. Normalize that field against legal
  moves, including pinned pawns; regression positions distinguish both
  cases (FIDE 9.2.3).
- Medium: `R/search.R` silently ignored depth on the UCI path. Forward
  the depth and retain a bounded one-second request; a fake engine
  records and checks the actual protocol.
- Medium: non-finite/fractional counts caused coercion failures or
  unbounded work. Validate before conversion and avoid integer overflow
  in the ply limit.
- Medium: seeded puzzles changed the caller’s RNG when optional withr
  was absent. Preserve and restore the base RNG explicitly.
- Documentation: replace unsupported competitor comparisons and
  exhaustive-correctness language with the actual reference-position
  coverage.

Rule source checked: <https://handbook.fide.com/chapter/E012023>

## Roadmap and completion

1.  Essential repairs: correct the confirmed rule/process defects above
    and protect them with independent boundary cases. Implemented and
    locally validated.
2.  Everyday use: preserve user state, validate invalid inputs, install
    the package, exercise play/analysis and the app. Completed for the
    paths below.
3.  Release preparation: synchronize documentation and package checks.
    Local candidate prepared; platform CI and maintainer publication
    review remain.
4.  Deferred enhancements: retain the focused supported model; do not
    add engines, rule variants or infrastructure without an explicit use
    case and validation.

## Actual verification

R 4.6.1 on ARM64 macOS, 30 October 2026:

- Final source-package build/check, including vignettes: **Status OK**,
  897 assertions, 19 conditional skips; no test failures or warnings.
  Full source testing additionally exercised non-CRAN paths.
- Fresh installed-package journey: fool’s mate, FEN/PGN round trips,
  Sicilian identification, deterministic puzzles with RNG restoration,
  and legal search output passed.
- Installed Shiny app in Chromium: human move and engine reply, transfer
  to study, openings, puzzle hint and new-game reset passed with no page
  errors.

Exact command results and logs are retained locally in
`/Users/rh/Documents/GitHub/.repository-audit/2026-10-30-rheller-refinement/gambitR/`.
Failures preceding fixes remain there alongside the final evidence.

## First use from this checkout

Install R (tested with 4.6.1). For compiled dependencies use Xcode
command-line tools on macOS, Rtools on Windows, or the matching Linux
C/C++ toolchain. From this repository, install dependencies and the
local candidate:

``` sh
Rscript --vanilla -e 'install.packages("remotes", repos="https://cloud.r-project.org"); remotes::install_local(".", dependencies=TRUE, upgrade="never", build_vignettes=FALSE)'
Rscript --vanilla -e 'gambitR::gm_run_app()'
```

Open the local URL printed by Shiny. The README gives the scriptable
workflow. To repeat source tests, run
`Rscript --vanilla -e 'pkgload::load_all(); testthat::test_local(stop_on_failure=TRUE)'`
after installing the development dependencies.

## Limits and next release action

A real Stockfish binary was unavailable: the client protocol was tested
with a controlled external-process fixture, not a real engine. Deep
perft is finite reference coverage, not a formal correctness proof.
Windows/Linux and hosted CI were not rerun.

Review the local diff and run required platform CI on the chosen release
commit; then decide whether to publish. No hosted result or external
acceptance is claimed.
