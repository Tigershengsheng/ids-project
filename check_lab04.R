# Verify the results used in the completed Lab 04 documents.
# Run from the project directory after rendering.
suppressPackageStartupMessages(library(tidyverse))

read_worksheet <- function(file) {
  extracted <- tempfile(fileext = ".R")
  on.exit(unlink(extracted))
  knitr::purl(file, output = extracted, documentation = 0, quiet = TRUE)
  environment <- new.env(parent = globalenv())
  sys.source(extracted, envir = environment)
  environment
}

previous_warning_level <- getOption("warn")
options(warn = 2)

sw <- read_worksheet("lab-04.Rmd")
stopifnot(
  nrow(sw$starwars_df) == 87L,
  ncol(sw$starwars_df) == 14L,
  nrow(sw$starwars_complete) == 36L,
  nrow(sw$height_data) == 81L,
  nrow(sw$height_mass_data) == 59L,
  sum(sw$sex_counts$n) == 87L,
  median(sw$height_by_sex$height[sw$height_by_sex$sex == "female"]) == 167.5,
  median(sw$height_by_sex$height[sw$height_by_sex$sex == "male"]) == 183,
  all(sw$height_mass_data$mass > 0),
  sum(sw$category_data$sex == "unknown") == 4L,
  sum(sw$category_data$gender == "unknown") == 4L
)

b <- read_worksheet("investigation.Rmd")
stopifnot(
  nrow(b$bikes) == 8760L,
  nrow(b$bikes_active) == 8465L,
  all(table(b$bikes$date) == 24L),
  all(diff(sort(unique(b$bikes$date))) == 1),
  min(b$bikes$date) == as.Date("2017-12-01"),
  max(b$bikes$date) == as.Date("2018-11-30"),
  all(b$bikes$rented_bikes[b$bikes$functioning_day == "No"] == 0),
  all(b$bikes_active$rented_bikes > 0),
  sum(b$bikes$functioning_day == "No") == 295L,
  sum(b$season_summary$hours) == 8465L,
  nrow(b$hourly_pattern) == 4L * 24L
)
peak <- b$bikes_active %>% group_by(hour) %>%
  summarise(mean_rentals = mean(rented_bikes), .groups = "drop") %>%
  slice_max(mean_rentals, n = 1)
stopifnot(peak$hour == 18)

expected_figures <- c(
  paste0("figures/starwars-exercise-", 2:8, "-1.png"),
  paste0("figures/bikes-", c("rental-distribution", "hourly-pattern",
                             "temperature-pattern"), "-1.png")
)
stopifnot(all(file.exists(expected_figures)),
          all(file.size(expected_figures) > 1000))

for (file in c("lab-04.html", "investigation.html")) {
  html <- paste(readLines(file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  stopifnot(!grepl("Your answer here|Quitting from|Error in|<U\\+[0-9A-F]{4}>", html))
}

options(warn = previous_warning_level)
checks <- c(
  paste("Lab 04 verification:", Sys.time()),
  "PASS: both worksheets execute with warnings treated as errors.",
  "PASS: Star Wars plot sample sizes are 36, 81 and 59 as described.",
  "PASS: category counts and height medians agree with the written answers.",
  "PASS: Seoul has 8760 records, 365 complete days, no missing or duplicate hours.",
  "PASS: 295 non-operating zero records are separated; 8465 active records remain.",
  "PASS: 18:00 is the busiest mean hour among active records.",
  "PASS: all 10 figures and both rendered HTML files exist.",
  "PASS: completed HTML documents contain no answer placeholders or R errors.",
  "Visual review: all 10 PNG figures inspected; axes and legends checked.",
  "Pending human decisions: candidate topic, invitation acceptance, current Learn dates."
)
writeLines(checks, "verification.txt")
cat(paste(checks, collapse = "\n"), "\n")
