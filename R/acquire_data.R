# Optional recovery of the unchanged source CSVs.
# The normal rendering pipeline uses the copies already supplied.
source("R/setup.R")
dir.create("data", showWarnings = FALSE)
uci <- "data/uci_cdc_diabetes_891.csv"
three <- "data/diabetes_012_health_indicators_BRFSS2015.csv"
uci_hash <- "9f71fda9d4ae5f4878c99b9233b6a16accfa9a17c194116a6b78100540934964"
three_hash <- "a971809d0786d2d7d7f6070f83dfe8af9d860ea33a79e0e2701c8a49f78f9861"
if (!file.exists(uci)) {
  tmp <- tempfile(tmpdir="data", fileext=".csv")
  download.file("https://archive.ics.uci.edu/static/public/891/data.csv",
                tmp, mode="wb")
  stopifnot(identical(digest::digest(file=tmp,algo="sha256"),uci_hash))
  stopifnot(file.rename(tmp,uci))
}
if (!file.exists(three)) {
  tmp <- tempfile(tmpdir="data",fileext=".zip")
  download.file("https://www.kaggle.com/api/v1/datasets/download/alexteboul/diabetes-health-indicators-dataset",
                tmp, mode="wb")
  unzip(tmp, files="diabetes_012_health_indicators_BRFSS2015.csv", exdir="data")
}
stopifnot(identical(digest::digest(file=uci,algo="sha256"),uci_hash),
          identical(digest::digest(file=three,algo="sha256"),three_hash))
message("Both data files match the analysed versions.")
