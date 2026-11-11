# Open student-dropout-final.Rproj in RStudio, then run source('render_project.R').
source("R/setup.R")
if(!rmarkdown::pandoc_available()) {
  candidate <- "D:/rstudio/resources/app/bin/quarto/bin/tools"
  if(file.exists(file.path(candidate,"pandoc.exe"))) Sys.setenv(RSTUDIO_PANDOC=candidate)
}
if(!rmarkdown::pandoc_available()) stop("Pandoc is needed. Run from RStudio or set RSTUDIO_PANDOC.")
invisible(load_results())
rmarkdown::render("presentation.Rmd",envir=new.env(parent=globalenv()),encoding="UTF-8",quiet=TRUE)
for(file in c("study-guide.Rmd","speaker-notes.Rmd")) {
  if(file.exists(file)) rmarkdown::render(file,envir=new.env(parent=globalenv()),encoding="UTF-8",quiet=TRUE)
}
for(file in c("docs/requirements-checklist.md","docs/course-map.md","docs/analysis-plan.md","docs/source-notes.md","docs/slide-outline.md","docs/data-to-viz-review.md","docs/learning-process.md","docs/regression-course-update.md")) {
  if(file.exists(file)) rmarkdown::render(file,output_format=rmarkdown::html_document(
    self_contained=TRUE,toc=TRUE,toc_depth=2,theme="readable",mathjax=NULL),encoding="UTF-8",quiet=TRUE)
}
message("Rendered presentation and available companion documents.")
