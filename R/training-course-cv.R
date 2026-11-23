# Compare fixed enrolment models within the original training partition.
training_course_cv <- function() {
  seed <- 20261123L
  fold_count <- 5L
  membership <- read.csv("results/split-membership.csv")
  training <- membership[membership$split == "Training", ]
  raw <- read.csv("data/data.csv", sep = ";", check.names = FALSE,
                  fileEncoding = "UTF-8-BOM")
  rows <- raw[training$row_id, ]
  stopifnot(!anyDuplicated(training$profile_id),
            identical(rows$Target, training$target))

  records <- data.frame(
    dropout = as.integer(rows$Target == "Dropout"),
    age10 = rows[["Age at enrollment"]] / 10,
    admission10 = rows[["Admission grade"]] / 10,
    course = factor(rows$Course)
  )
  # Allocate the same folds to both models, balancing original label and gender.
  set.seed(seed)
  strata <- interaction(training$target, training$gender, drop = TRUE)
  folds <- integer(nrow(records))
  for (indices in split(seq_len(nrow(records)), strata)) {
    folds[indices] <- sample(rep(seq_len(fold_count), length.out = length(indices)))
  }

  score_fold <- function(fold, predictors) {
    fitting <- records[folds != fold, ]
    assessment <- records[folds == fold, ]
    stopifnot(length(unique(fitting$course)) == nlevels(records$course))
    fit <- glm(predictors, data = fitting, family = binomial())
    stopifnot(fit$converged, all(is.finite(coef(fit))))
    probability <- predict(fit, newdata = assessment, type = "response")
    observed <- assessment$dropout
    positives <- sum(observed == 1L)
    negatives <- sum(observed == 0L)
    stopifnot(positives > 0, negatives > 0)
    # The rank formula gives ties half credit.
    positive_ranks <- sum(rank(probability)[observed == 1L])
    auc <- (positive_ranks - positives * (positives + 1) / 2) / (positives * negatives)
    c(AUC = auc, Brier = mean((observed - probability)^2))
  }

  without_course <- t(vapply(seq_len(fold_count), score_fold, numeric(2),
    predictors = dropout ~ age10 + admission10))
  with_course <- t(vapply(seq_len(fold_count), score_fold, numeric(2),
    predictors = dropout ~ age10 + admission10 + course))
  fold_results <- data.frame(
    fold = seq_len(fold_count), n = tabulate(folds, nbins = fold_count),
    auc_without_course = without_course[, "AUC"], auc_with_course = with_course[, "AUC"],
    brier_without_course = without_course[, "Brier"], brier_with_course = with_course[, "Brier"]
  )
  average <- rbind(colMeans(without_course), colMeans(with_course))
  rownames(average) <- c("without_course", "with_course")
  list(seed = seed, n = nrow(records), folds = fold_results, average = average)
}
