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
  stale <- !file.exists(path)
  if (!stale) {
    r <- readRDS(path)
    stale <- !identical(r$data_sha256,file_sha256("data/data.csv")) ||
      !identical(r$analysis_sha256,file_sha256("R/analysis.R")) ||
      !identical(r$plan_sha256,file_sha256("docs/analysis-plan.md"))
  }
  if (stale) source("R/analysis.R",local=FALSE)
  readRDS(path)
}
