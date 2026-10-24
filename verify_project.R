source("R/setup.R")
checks <- character()
check <- function(ok, label) {
  if (!isTRUE(ok)) stop("CHECK FAILED: ", label)
  checks <<- c(checks, paste("PASS", label))
}
r <- load_results()
check(r$audit$n == 253680 && r$audit$n_positive == 35346,
      "Source row count and verified positive count")
check(r$audit$n_prediabetes == 4631, "Prediabetes mapping recorded")
check(identical(r$audit$data_sha256,
                "9f71fda9d4ae5f4878c99b9233b6a16accfa9a17c194116a6b78100540934964"),
      "UCI raw data hash")
check(identical(r$audit$original_sha256,
                "a971809d0786d2d7d7f6070f83dfe8af9d860ea33a79e0e2701c8a49f78f9861"),
      "Original three-category raw data hash")
check(r$model_converged && r$model_rank == 24, "Primary model convergence and full rank")
splits <- read.csv("results/data_split.csv")
pred <- read.csv("results/test_predictions.csv")
raw <- read.csv("data/uci_cdc_diabetes_891.csv")
check(nrow(splits) == nrow(raw) && !anyDuplicated(splits$ID),
      "Every source row has exactly one split")
check(sum(splits$split == "training") == r$train_n &&
        sum(splits$split == "test") == r$test_n &&
        r$train_n + r$test_n == nrow(raw), "Training and test sizes")
check(setequal(pred$ID, splits$ID[splits$split == "test"]) &&
        !anyDuplicated(pred$ID), "Test predictions cover exactly the held-out rows")
check(identical(as.integer(pred$Outcome),
                as.integer(raw$Diabetes_binary[match(pred$ID, raw$ID)])),
      "Saved test outcomes match raw data")
check(all(is.finite(pred$Adjusted)) && all(pred$Adjusted > 0 & pred$Adjusted < 1),
      "Test probabilities are finite and within bounds")
check(abs(r$metrics$Accuracy[1] - mean(pred$Outcome == 0)) < 1e-12 &&
        r$metrics$Sensitivity[1] == 0, "Constant baseline is evaluated correctly")
# Independent grouped-threshold AUC calculation, compared with the analysis' rank formula.
auc_grouped <- function(y, p) {
  g <- aggregate(cbind(Pos = y, Neg = 1-y), by = list(p = p), FUN = sum)
  g <- g[order(g$p), ]
  smaller_negatives <- cumsum(g$Neg) - g$Neg
  sum(g$Pos * (smaller_negatives + .5 * g$Neg)) / (sum(y) * sum(1-y))
}
for (j in 2:3) {
  p <- pred[[if (j == 2) "Covariates" else "Adjusted"]]
  y <- pred$Outcome
  check(abs(auc_grouped(y,p) - r$metrics$AUC[j]) < 1e-10,
        paste("Independently recomputed AUC:", r$metrics$Model[j]))
  check(abs(mean((p-y)^2) - r$metrics$Brier[j]) < 1e-10,
        paste("Brier score matches saved predictions:", r$metrics$Model[j]))
  check(abs(mean(p[y == 1] >= .5) - r$metrics$Sensitivity[j]) < 1e-12,
        paste("Sensitivity matches saved predictions:", r$metrics$Model[j]))
}
check(all(diff(r$standardised$Estimate) < 0),
      "Reported ordering of standardised income probabilities")
check(abs(r$gap$adjusted -
            (r$standardised$Estimate[1] - r$standardised$Estimate[8])) < 1e-12,
      "Reported adjusted gap matches standardised probabilities")
check(r$gap$lower < r$gap$adjusted && r$gap$adjusted < r$gap$upper,
      "Gap interval contains its estimate")
check(all(r$standardised$lower >= 0 & r$standardised$upper <= 1 &
            r$standardised$lower <= r$standardised$Estimate &
            r$standardised$upper >= r$standardised$Estimate),
      "Probability intervals have valid bounds")
check(all(r$sensitivity$OR > 1), "Sensitivity conclusions match estimates")
expected <- c("report.Rmd","report.html","presentation.Rmd","presentation.html",
              "investigation.Rmd","investigation.html",
              "study-guide.md","study-guide.html","speaker-notes.md","speaker-notes.html",
              "cdc-diabetes-final.Rproj","README.md","data/README.md",
              "vendor/remark-latest.min.js")
check(all(file.exists(expected)), "All expected deliverables exist")
pngs <- list.files("figures", pattern = "\\.png$", recursive = TRUE, full.names = TRUE)
check(length(pngs) == 12 && all(file.info(pngs)$size > 10000),
      "All twelve report and slide figures exist")
source_files <- c("report.Rmd","presentation.Rmd","investigation.Rmd",
                  "study-guide.md","speaker-notes.md","README.md","data/README.md")
check(!any(vapply(source_files,
                  function(f) any(grepl("@@", readLines(f, warn=FALSE), fixed=TRUE)),
                  logical(1))), "No authoring markers remain")
html <- paste(readLines("report.html", warn=FALSE, encoding="UTF-8"), collapse="\n")
check(!grepl('<pre class="r"', html, fixed=TRUE), "Code is hidden in the final report")
body <- sub('(?s)^.*?<div id="research-question"[^>]*>', "", html, perl=TRUE)
body <- sub('(?s)<div id="references".*$', "", body, perl=TRUE)
body <- gsub("(?s)<table.*?</table>", " ", body, perl=TRUE)
body <- gsub('(?s)<p class="caption".*?</p>', " ", body, perl=TRUE)
body <- gsub("<[^>]+>", " ", body)
body <- gsub("&[A-Za-z0-9#]+;", " ", body)
words <- regmatches(body, gregexpr("[[:alnum:]]+(?:['-][[:alnum:]]+)*",body,perl=TRUE))[[1]]
check(length(words) >= 1300 && length(words) <= 1650,
      paste("Report narrative word count:", length(words)))
for (file in c("report.html","presentation.html","study-guide.html","speaker-notes.html")) {
  h <- paste(readLines(file,warn=FALSE,encoding="UTF-8"),collapse="\n")
  check(!grepl('<script[^>]+src=["\\x27]https?://',h,perl=TRUE),
        paste("No remote script dependency:", file))
}
writeLines(c(checks, "", paste("Narrative words (excluding tables, figures and references):",length(words)),
             paste("R version:",R.version.string),
             "Visual browser checks are recorded separately in results/browser-check.json."),
           "results/verification.txt")
jsonlite::write_json(list(passed=length(checks),report_narrative_words=length(words),
                          checks=checks), "results/verification.json",
                     auto_unbox=TRUE,pretty=TRUE)
cat(paste(checks,collapse="\n"),"\n")
