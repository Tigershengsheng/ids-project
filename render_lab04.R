# Run from this project's folder, or source this script in RStudio.
needed <- c("tidyverse", "knitr", "rmarkdown")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install these packages first: ", paste(missing, collapse = ", "))

if (!rmarkdown::pandoc_available()) {
  candidate <- "D:/rstudio/resources/app/bin/quarto/bin/tools"
  if (file.exists(file.path(candidate, "pandoc.exe"))) {
    Sys.setenv(RSTUDIO_PANDOC = candidate)
  }
}

for (file in c("lab-04.Rmd", "investigation.Rmd")) {
  rmarkdown::render(file, envir = new.env(parent = globalenv()),
                    encoding = "UTF-8", quiet = TRUE)
  message("Rendered: ", sub("\\.Rmd$", ".html", file))
}

writeLines(capture.output(sessionInfo()), "session-info.txt", useBytes = TRUE)

rmarkdown::render("study-guide.md", output_file = "study-guide.html",
  output_format = rmarkdown::html_document(toc = TRUE, theme = "readable", mathjax = NULL),
  encoding = "UTF-8", quiet = TRUE)
message("Rendered: study-guide.html")
