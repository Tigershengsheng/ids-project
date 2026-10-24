# Open cdc-diabetes-final.Rproj, then source this file.
source("R/setup.R")
if (!requireNamespace("xaringan", quietly = TRUE)) {
  stop("Install xaringan first: source('R/install.R')")
}
if (!rmarkdown::pandoc_available()) {
  candidate <- "D:/rstudio/resources/app/bin/quarto/bin/tools"
  if (file.exists(file.path(candidate, "pandoc.exe"))) Sys.setenv(RSTUDIO_PANDOC = candidate)
}
if (!rmarkdown::pandoc_available()) stop("Run this script from RStudio, which includes Pandoc.")
source("R/analysis.R", local = FALSE)
for (file in c("report.Rmd", "investigation.Rmd", "presentation.Rmd")) {
  rmarkdown::render(file, envir = new.env(parent = globalenv()),
                    encoding = "UTF-8", quiet = TRUE)
  message("Rendered ", sub("\\.Rmd$", ".html", file))
}
for (file in c("study-guide.md", "speaker-notes.md")) {
  rmarkdown::render(file, output_file = sub("\\.md$", ".html", file),
                    output_format = rmarkdown::html_document(
                      self_contained = TRUE, toc = TRUE, toc_depth = 2,
                      theme = "readable", css = "report.css", mathjax = NULL),
                    encoding = "UTF-8", quiet = TRUE)
  message("Rendered ", sub("\\.md$", ".html", file))
}
writeLines(capture.output(sessionInfo()), "results/session-info-render.txt")
message("All project documents rendered.")
