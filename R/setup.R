if (dir.exists("R-library")) .libPaths(c(normalizePath("R-library"), .libPaths()))
options(stringsAsFactors = FALSE, scipen = 6)
needed <- c("dplyr", "tidyr", "readr", "ggplot2", "knitr", "rmarkdown", "jsonlite", "digest", "xaringan")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install packages first with source('R/install.R'): ", paste(missing, collapse = ", "))
num <- function(x, digits = 0) formatC(x, format = "f", digits = digits, big.mark = ",")
pct <- function(x, digits = 1) ifelse(is.na(x), "not estimable", paste0(num(100*x, digits), "%"))
pp <- function(x, digits = 1) paste0(num(100*x, digits), " percentage points")
interval_pct <- function(lo, hi, digits = 1) paste0(pct(lo,digits), " to ", pct(hi,digits))
file_sha256 <- function(path) {
  bytes <- readBin(path,what="raw",n=file.info(path)$size)
  digest::digest(bytes,algo="sha256",serialize=FALSE)
}
slide_plot <- function(path, height = "380px", alt = basename(path)) {
  cat(sprintf('<img class="data-figure" src="%s" alt="%s" style="max-height:%s;">',
              knitr::image_uri(path), alt, height))
}
load_results <- function() {
  path <- "results/analysis.rds"
  companion_outputs <- c(
    "results/split-membership.csv", "results/split-counts.csv",
    "results/validation-thresholds.csv", "results/test-metrics.csv",
    "results/coded-unknown-audit.csv", "results/fairness-group-metrics.csv",
    "results/fairness-gaps.csv", "results/fairness-gender-inclusive.csv",
    "results/enrolled-definition-sensitivity.csv", "results/test-metric-intervals.csv",
    "results/test-predictions.csv", "results/primary-coefficients.csv",
    "results/fitted-models.rds", "results/bootstrap-gaps.csv",
    "results/calibration-bins.csv", "results/training-course-composition.csv",
    "results/fairness-threshold-05.csv", "results/outcome-counts.csv",
    "results/training-summary.csv", "results/variable-timing-audit.csv",
    "results/fairness-group-intervals.csv", "results/frozen-configuration.json"
  )
  stale <- !all(file.exists(c(path, companion_outputs)))
  if (!stale) {
    r <- readRDS(path)
    stale <- !identical(r$data_sha256,file_sha256("data/data.csv")) ||
      !identical(r$analysis_sha256,file_sha256("R/analysis.R")) ||
      !identical(r$plan_sha256,file_sha256("docs/analysis-plan.md"))
  }
  if (stale) source("R/analysis.R",local=FALSE)
  readRDS(path)
}
