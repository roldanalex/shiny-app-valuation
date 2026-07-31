# Pure helper functions (no Shiny session needed) - unit-tested in
# tests/testthat/test-app-helpers.R

#' Coerce a raw numeric input value to a safe non-negative count.
#' NULL, NA, non-numeric, non-finite, and negative values become 0.
clean_count <- function(x) {
  if (is.null(x) || length(x) != 1) return(0)
  x <- suppressWarnings(as.numeric(x))
  if (is.na(x) || !is.finite(x) || x < 0) return(0)
  x
}

#' Parse a URL query parameter as a bounded number.
#' Returns NULL (meaning "ignore") unless the value parses to a finite
#' number within [lo, hi].
parse_num_param <- function(x, lo = 0, hi = 5e6) {
  if (is.null(x) || length(x) != 1) return(NULL)
  v <- suppressWarnings(as.numeric(x))
  if (is.na(v) || !is.finite(v) || v < lo || v > hi) return(NULL)
  v
}

#' Build a validated language mix from raw manual-entry inputs.
#' Takes a named list of raw values; returns a named list containing only
#' languages with a positive, finite line count (possibly empty).
build_language_mix <- function(raw_mix) {
  cleaned <- lapply(raw_mix, clean_count)
  Filter(function(x) x > 0, cleaned)
}
