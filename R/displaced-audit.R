displaced_audit <- function() {
  raw <- read.csv("data/data.csv", sep = ";", check.names = FALSE,
                  fileEncoding = "UTF-8-BOM")
  test <- read.csv("results/test-predictions.csv")
  config <- jsonlite::read_json("results/frozen-configuration.json")
  stopifnot(nrow(test) == config$test_n, !anyDuplicated(test$row_id),
            all(test$row_id %in% seq_len(nrow(raw))))
  rows <- raw[test$row_id, ]
  stopifnot(identical(rows$Target, test$target),
            identical(as.integer(rows$Target == "Dropout"), test$dropout),
            identical(ifelse(rows$Gender == 0, "Female", "Male"), test$gender),
            all(rows$Displaced %in% 0:1),
            all(test$flag == (test$probability >= config$threshold)),
            all(test$flag_05 == (test$probability >= 0.50)))
  results <- lapply(c(config$threshold, 0.50), function(threshold) {
    do.call(rbind, lapply(0:1, function(group) {
      in_group <- rows$Displaced == group
      dropout <- test$dropout[in_group] == 1
      warned <- test$probability[in_group] >= threshold
      missed <- sum(dropout & !warned)
      false_warnings <- sum(!dropout & warned)
      data.frame(threshold, group, n = sum(in_group), dropouts = sum(dropout),
                 no_dropout = sum(!dropout), missed, false_warnings,
                 fnr = missed / sum(dropout), fpr = false_warnings / sum(!dropout))
    }))
  })
  do.call(rbind, results)
}
