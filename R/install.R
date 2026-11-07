dir.create("R-library",showWarnings=FALSE)
.libPaths(c(normalizePath("R-library"),.libPaths()))
needed <- c("dplyr","tidyr","readr","ggplot2","knitr","rmarkdown","jsonlite","digest","xaringan")
missing <- needed[!vapply(needed,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) install.packages(missing,lib=.libPaths()[1],repos="https://cloud.r-project.org")
stopifnot(all(vapply(needed,requireNamespace,logical(1),quietly=TRUE)))
message("Required R packages are available.")
