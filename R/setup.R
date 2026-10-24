# Run from the RStudio project folder.
if (dir.exists("R-library")) .libPaths(c(normalizePath("R-library"), .libPaths()))
options(stringsAsFactors = FALSE, scipen = 7)
needed <- c("ggplot2", "dplyr", "tidyr", "knitr", "rmarkdown", "jsonlite", "digest")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install the missing packages: ", paste(missing, collapse = ", "))
income_labels <- c("< $10,000", "$10,000-14,999", "$15,000-19,999",
                   "$20,000-24,999", "$25,000-34,999", "$35,000-49,999",
                   "$50,000-74,999", "$75,000 or more")
age_labels <- c("18-24", "25-29", "30-34", "35-39", "40-44", "45-49",
                "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80+")
num <- function(x, digits = 0) formatC(x, format = "f", digits = digits, big.mark = ",")
pct <- function(x, digits = 1) paste0(num(100 * x, digits), "%")
pp <- function(x, digits = 1) paste0(num(100 * x, digits), " percentage points")
load_results <- function() {
  stale <- !file.exists("results/analysis.rds")
  if (!stale) {
    existing <- readRDS("results/analysis.rds")
    current <- digest::digest(paste(readLines("R/analysis.R", warn = FALSE), collapse = "\n"),
                              algo = "sha256", serialize = FALSE)
    stale <- !identical(existing$analysis_source_sha256, current) ||
      !identical(existing$audit$data_sha256,
                 digest::digest(file = "data/uci_cdc_diabetes_891.csv", algo = "sha256")) ||
      !identical(existing$audit$original_sha256,
                 digest::digest(file = "data/diabetes_012_health_indicators_BRFSS2015.csv", algo = "sha256"))
  }
  if (stale) source("R/analysis.R", local = FALSE)
  readRDS("results/analysis.rds")
}
slide_plot <- function(file, height = "430px") {
  cat(sprintf('<img alt="%s" src="%s" style="max-width:100%%;max-height:%s;object-fit:contain;display:block;margin:0 auto;">',
              basename(file), knitr::image_uri(file), height))
}
