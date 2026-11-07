# Open the unchanged source data and a smaller view of the project variables.
# Gender is an audit variable, not an input to the primary prediction model.
source("R/setup.R")
students_raw <- readr::read_delim(
  "data/data.csv", delim = ";",
  locale = readr::locale(decimal_mark = "."),
  trim_ws = TRUE, show_col_types = FALSE, name_repair = "minimal"
)
stopifnot(nrow(students_raw) == 4424L, ncol(students_raw) == 37L)
used_variables <- students_raw[, c(
  "Age at enrollment", "Admission grade", "Course", "Gender", "Target"
)]
if (interactive()) {
  View(students_raw, title = "UCI 697 - original data")
  View(used_variables, title = "3 model inputs - Gender audit - Target outcome")
}
message("Original data: 4424 rows, 37 columns. Smaller view: 5 original columns.")
print(table(students_raw$Target))
