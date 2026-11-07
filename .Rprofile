# Make project-local packages visible before R Markdown resolves its output format.
# Loading this file does not fit a model, run the analysis, or install packages.
local({
  project_library <- file.path(getwd(), "R-library")
  if (dir.exists(project_library)) {
    .libPaths(c(normalizePath(project_library, winslash = "/"), .libPaths()))
  }
})
