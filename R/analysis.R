# Reproducible analysis. No network access is needed after data acquisition.
source("R/setup.R")
library(ggplot2)
library(dplyr)
library(tidyr)
for (folder in c("results", "figures")) dir.create(folder, showWarnings = FALSE)
message("Reading and auditing the original data...")
raw <- read.csv("data/uci_cdc_diabetes_891.csv")
original <- read.csv("data/diabetes_012_health_indicators_BRFSS2015.csv")
feature_names <- setdiff(names(raw), c("ID", "Diabetes_binary"))
stopifnot(nrow(raw) == 253680L, ncol(raw) == 23L,
          length(feature_names) == 21L, !anyNA(raw),
          identical(as.integer(raw$ID), seq.int(0L, nrow(raw) - 1L)),
          identical(as.integer(raw$Diabetes_binary), as.integer(original$Diabetes_012 == 2)),
          isTRUE(all.equal(as.matrix(raw[feature_names]),
                           as.matrix(original[feature_names]), check.attributes = FALSE)))
stopifnot(all(raw$Income %in% 1:8), all(raw$Age %in% 1:13),
          all(raw$Sex %in% 0:1), all(raw$BMI > 0))
label_audit <- as.data.frame(table(original$Diabetes_012, raw$Diabetes_binary))
names(label_audit) <- c("Original_class", "Binary_code", "N")
label_audit <- label_audit[label_audit$N > 0, ]
write.csv(label_audit, "results/label_audit.csv", row.names = FALSE)
write.csv(data.frame(variable = names(raw), missing = colSums(is.na(raw))),
          "results/missing_values.csv", row.names = FALSE)
audit <- list(
  n = nrow(raw), n_features = length(feature_names),
  n_positive = sum(raw$Diabetes_binary), n_prediabetes = sum(original$Diabetes_012 == 1),
  n_no_diabetes = sum(original$Diabetes_012 == 0),
  positive_fraction = mean(raw$Diabetes_binary),
  duplicated_response_profiles = sum(duplicated(raw[setdiff(names(raw), "ID")])),
  bmi_over_60 = sum(raw$BMI > 60),
  data_sha256 = digest::digest(file = "data/uci_cdc_diabetes_891.csv", algo = "sha256"),
  original_sha256 = digest::digest(file = "data/diabetes_012_health_indicators_BRFSS2015.csv", algo = "sha256")
)
d <- data.frame(
  ID = raw$ID, Diabetes = as.integer(raw$Diabetes_binary),
  OriginalStatus = as.integer(original$Diabetes_012),
  IncomeCode = as.integer(raw$Income),
  Income = factor(as.character(raw$Income), levels = as.character(8:1)),
  Age = factor(age_labels[raw$Age], levels = age_labels),
  AgeCode = as.integer(raw$Age),
  BMI = as.numeric(raw$BMI),
  Sex = factor(raw$Sex, levels = c(0, 1), labels = c("Female", "Male"))
)
# Identical answers can come from different respondents. Keep these records.
# Split by respondent row, with the outcome proportion preserved in both sets.
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(20261024)
training_rows <- sort(unlist(lapply(split(seq_len(nrow(d)), d$Diabetes),
                                  function(ids) sample(ids, floor(0.8 * length(ids))))))
train <- d[training_rows, ]
test <- d[-training_rows, ]
stopifnot(length(intersect(train$ID, test$ID)) == 0L,
          nrow(train) + nrow(test) == nrow(d))
write.csv(data.frame(ID = d$ID, split = ifelse(seq_len(nrow(d)) %in% training_rows,
                                             "training", "test")),
          "results/data_split.csv", row.names = FALSE)
wilson <- function(k, n) {
  z <- qnorm(.975)
  p <- k / n
  centre <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
  data.frame(lower = centre - half, upper = centre + half)
}
raw_income <- train %>%
  group_by(IncomeCode) %>%
  summarise(N = n(), Cases = sum(Diabetes), Rate = mean(Diabetes),
            MeanBMI = mean(BMI), Age60plus = mean(AgeCode >= 9),
            Female = mean(Sex == "Female"), .groups = "drop")
raw_income <- cbind(raw_income, wilson(raw_income$Cases, raw_income$N))
raw_income$IncomeLabel <- factor(income_labels[raw_income$IncomeCode],
                                levels = rev(income_labels))
write.csv(raw_income, "results/income_summary_training.csv", row.names = FALSE)
message("Fitting the prespecified logistic regression models...")
unadjusted <- glm(Diabetes ~ Income, family = binomial(), data = train)
covariates <- glm(Diabetes ~ Age + splines::ns(BMI, df = 3) + Sex,
                  family = binomial(), data = train)
adjusted <- glm(Diabetes ~ Income + Age + splines::ns(BMI, df = 3) + Sex,
                family = binomial(), data = train)
linear_bmi <- glm(Diabetes ~ Income + Age + BMI + Sex,
                  family = binomial(), data = train)
without_prediabetes <- glm(Diabetes ~ Income + Age + splines::ns(BMI, df = 3) + Sex,
                           family = binomial(),
                           data = train[train$OriginalStatus != 1, ])
without_extreme_bmi <- glm(Diabetes ~ Income + Age + splines::ns(BMI, df = 3) + Sex,
                           family = binomial(), data = train[train$BMI <= 60, ])
fits <- list(unadjusted = unadjusted, covariates = covariates, adjusted = adjusted,
             linear_bmi = linear_bmi, without_prediabetes = without_prediabetes,
             without_extreme_bmi = without_extreme_bmi)
stopifnot(all(vapply(fits, function(m) m$converged && !anyNA(coef(m)), logical(1))))
stopifnot(adjusted$rank == length(coef(adjusted)))
odds_ratios <- function(model) {
  terms <- grep("^Income", names(coef(model)), value = TRUE)
  se <- sqrt(diag(vcov(model)))[terms]
  data.frame(IncomeCode = as.integer(sub("Income", "", terms)),
             OR = exp(coef(model)[terms]),
             lower = exp(coef(model)[terms] - 1.96 * se),
             upper = exp(coef(model)[terms] + 1.96 * se), row.names = NULL)
}
ors <- merge(odds_ratios(unadjusted), odds_ratios(adjusted), by = "IncomeCode",
             suffixes = c("_crude", "_adjusted"))
write.csv(ors, "results/income_odds_ratios.csv", row.names = FALSE)
# Give every income category the SAME empirical age/BMI/sex distribution.
# Aggregation makes this exact calculation faster; it does not change the weights.
reference <- aggregate(rep(1, nrow(train)),
                       by = list(Age = train$Age, Sex = train$Sex, BMI = train$BMI),
                       FUN = sum)
reference$weight <- reference$x / nrow(train)
V <- vcov(adjusted)
gradients <- vector("list", 8)
standardised <- do.call(rbind, lapply(1:8, function(code) {
  nd <- reference
  nd$Income <- factor(as.character(code), levels = levels(train$Income))
  tt <- delete.response(terms(adjusted))
  mf <- model.frame(tt, data = nd, xlev = adjusted$xlevels)
  X <- model.matrix(tt, mf, contrasts.arg = adjusted$contrasts)
  pr <- as.numeric(predict(adjusted, newdata = nd, type = "response"))
  stopifnot(isTRUE(all.equal(pr, as.numeric(plogis(X %*% coef(adjusted))),
                            tolerance = 1e-9)))
  estimate <- sum(reference$weight * pr)
  gradient <- colSums(X * as.numeric(reference$weight * pr * (1 - pr)))
  gradients[[code]] <<- gradient
  se <- sqrt(as.numeric(t(gradient) %*% V %*% gradient))
  data.frame(IncomeCode = code, Estimate = estimate,
             lower = max(0, estimate - 1.96 * se),
             upper = min(1, estimate + 1.96 * se))
}))
standardised$IncomeLabel <- factor(income_labels[standardised$IncomeCode],
                                  levels = rev(income_labels))
gradient_difference <- gradients[[1]] - gradients[[8]]
adjusted_gap <- standardised$Estimate[1] - standardised$Estimate[8]
gap_se <- sqrt(as.numeric(t(gradient_difference) %*% V %*% gradient_difference))
gap <- list(
  raw = raw_income$Rate[raw_income$IncomeCode == 1] -
    raw_income$Rate[raw_income$IncomeCode == 8],
  adjusted = adjusted_gap, lower = adjusted_gap - 1.96 * gap_se,
  upper = adjusted_gap + 1.96 * gap_se)
write.csv(standardised, "results/standardised_probabilities.csv", row.names = FALSE)
auc_rank <- function(y, p) {
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  (sum(rank(p, ties.method = "average")[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}
evaluate <- function(name, y, p) {
  p <- pmin(pmax(p, 1e-12), 1 - 1e-12)
  pred <- as.integer(p >= .5)
  data.frame(Model = name, AUC = auc_rank(y, p),
             Brier = mean((p - y)^2),
             LogLoss = -mean(y * log(p) + (1 - y) * log(1 - p)),
             Accuracy = mean(pred == y),
             Sensitivity = mean(pred[y == 1] == 1),
             Specificity = mean(pred[y == 0] == 0))
}
pred_base <- rep(mean(train$Diabetes), nrow(test))
pred_cov <- as.numeric(predict(covariates, newdata = test, type = "response"))
pred_adj <- as.numeric(predict(adjusted, newdata = test, type = "response"))
metrics <- rbind(evaluate("Constant baseline", test$Diabetes, pred_base),
                 evaluate("Age + BMI + sex", test$Diabetes, pred_cov),
                 evaluate("Age + BMI + sex + income", test$Diabetes, pred_adj))
write.csv(metrics, "results/test_metrics.csv", row.names = FALSE)
test_predictions <- data.frame(ID = test$ID, Outcome = test$Diabetes,
                               Covariates = pred_cov, Adjusted = pred_adj)
write.csv(test_predictions, "results/test_predictions.csv", row.names = FALSE)
calibration <- data.frame(Outcome = test$Diabetes, Prediction = pred_adj,
                         Decile = ceiling(rank(pred_adj, ties.method = "first") /
                                            (nrow(test) / 10))) %>%
  group_by(Decile) %>%
  summarise(N = n(), Cases = sum(Outcome), Observed = mean(Outcome),
            Predicted = mean(Prediction), .groups = "drop")
calibration <- cbind(calibration, wilson(calibration$Cases, calibration$N))
write.csv(calibration, "results/test_calibration.csv", row.names = FALSE)
lp <- qlogis(pmin(pmax(pred_adj, 1e-9), 1 - 1e-9))
cal_intercept <- glm(test$Diabetes ~ 1 + offset(lp), family = binomial())
cal_slope <- glm(test$Diabetes ~ lp, family = binomial())
sensitivity <- do.call(rbind, lapply(
  c("adjusted", "linear_bmi", "without_prediabetes", "without_extreme_bmi"),
  function(name) {
    m <- fits[[name]]
    low <- odds_ratios(m)
    low <- low[low$IncomeCode == 1, ]
    data.frame(Model = name, N = nobs(m), OR = low$OR,
               lower = low$lower, upper = low$upper)
  }))
write.csv(sensitivity, "results/sensitivity.csv", row.names = FALSE)
coefficients <- data.frame(term = names(coef(adjusted)),
                           estimate = coef(adjusted),
                           std_error = sqrt(diag(vcov(adjusted))), row.names = NULL)
write.csv(coefficients, "results/model_coefficients.csv", row.names = FALSE)
message("Creating figures...")
ink <- "#173042"; blue <- "#176B87"; orange <- "#C65A24"; muted <- "#697C89"
theme_set(theme_minimal(base_size = 13, base_family = "sans") +
            theme(plot.title = element_text(face = "bold", colour = ink, size = 17),
                  plot.subtitle = element_text(colour = muted, size = 11),
                  panel.grid.minor = element_blank(),
                  panel.grid.major.y = element_blank(),
                  axis.title = element_text(colour = ink),
                  legend.position = "bottom",
                  plot.caption = element_text(hjust = 0, colour = muted, size = 9),
                  plot.margin = margin(14, 20, 10, 12)))
percent_axis <- function(x) paste0(round(100 * x), "%")
save_plot <- function(name, p, width = 8.6, height = 5.2) {
  ggsave(file.path("figures", paste0(name, ".png")), p, width = width,
         height = height, dpi = 180, bg = "white")
}
p_raw <- ggplot(raw_income, aes(x = Rate, y = IncomeLabel)) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y",
                width = .17, colour = blue, linewidth = .6) +
  geom_point(colour = blue, size = 3) +
  scale_x_continuous(labels = percent_axis, limits = c(0, NA),
                     expand = expansion(mult = c(0, .1))) +
  labs(title = "Reported diabetes by household income",
       subtitle = "Observed proportions in the training sample",
       x = "Respondents reporting diabetes", y = "Annual household income",
       caption = "95% Wilson intervals; unweighted sample estimates")
save_plot("01-observed-income", p_raw)
plot_comparison <- rbind(
  data.frame(IncomeLabel = raw_income$IncomeLabel, Estimate = raw_income$Rate,
             lower = raw_income$lower, upper = raw_income$upper,
             Type = "Observed"),
  data.frame(IncomeLabel = standardised$IncomeLabel, Estimate = standardised$Estimate,
             lower = standardised$lower, upper = standardised$upper,
             Type = "Same age, BMI and sex distribution"))
plot_comparison$Type <- factor(plot_comparison$Type,
                               levels = c("Observed", "Same age, BMI and sex distribution"))
p_adj <- ggplot(plot_comparison,
                aes(x = Estimate, y = IncomeLabel, colour = Type, group = Type)) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y",
                width = .15, position = position_dodge(width = .45), linewidth = .6) +
  geom_point(position = position_dodge(width = .45), size = 2.8) +
  scale_colour_manual(values = c("#9AABB5", blue)) +
  scale_x_continuous(labels = percent_axis, limits = c(0, NA),
                     expand = expansion(mult = c(0, .1))) +
  labs(title = "Income differences after adjustment",
       subtitle = "Every income group is compared using the same covariate distribution",
       x = "Observed or model-standardised probability", y = "Annual household income",
       colour = NULL,
       caption = "Observed: Wilson intervals. Standardised: model-based 95% intervals.\nThese are sample comparisons, not national prevalence estimates or causal effects.")
save_plot("02-adjusted-income", p_adj, height = 5.7)
p_cal <- ggplot(calibration, aes(x = Predicted, y = Observed)) +
  geom_abline(intercept = 0, slope = 1, linetype = 2, colour = muted) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = .004, colour = blue) +
  geom_line(colour = blue, linewidth = .7) +
  geom_point(colour = blue, size = 2.8) +
  scale_x_continuous(labels = percent_axis) +
  scale_y_continuous(labels = percent_axis) +
  coord_equal(xlim = c(0, max(calibration$Predicted, calibration$upper) + .02),
              ylim = c(0, max(calibration$Predicted, calibration$upper) + .02)) +
  labs(title = "Calibration on the untouched test sample",
       subtitle = "Respondents grouped into ten bins by predicted probability",
       x = "Mean predicted probability", y = "Observed diabetes proportion",
       caption = "Dashed line: perfect agreement. Bars: 95% Wilson intervals for each bin.")
save_plot("03-test-calibration", p_cal, width = 7.4, height = 5.9)
age_summary <- train %>%
  mutate(IncomeBand = factor(ifelse(IncomeCode <= 4, "< $25,000",
                                    ifelse(IncomeCode <= 6, "$25,000-49,999", "$50,000 or more")),
                             levels = c("< $25,000", "$25,000-49,999", "$50,000 or more"))) %>%
  group_by(Age, IncomeBand) %>%
  summarise(N = n(), Rate = mean(Diabetes), .groups = "drop")
p_age <- ggplot(age_summary, aes(x = Age, y = Rate, colour = IncomeBand,
                                 group = IncomeBand)) +
  geom_line(linewidth = .85) + geom_point(size = 1.7) +
  scale_colour_manual(values = c(orange, blue, "#688E61")) +
  scale_y_continuous(labels = percent_axis) +
  theme(axis.text.x = element_text(angle = 40, hjust = 1)) +
  labs(title = "Age patterns within broad income groups",
       x = "Age category (years)", y = "Observed diabetes proportion",
       colour = "Annual income", caption = "Training sample; broad income bands are used only for this descriptive figure.")
save_plot("04-age-patterns", p_age)
forest <- odds_ratios(adjusted)
forest$IncomeLabel <- factor(income_labels[forest$IncomeCode], levels = rev(income_labels))
p_or <- ggplot(forest, aes(x = OR, y = IncomeLabel)) +
  geom_vline(xintercept = 1, linetype = 2, colour = muted) +
  geom_errorbar(aes(xmin = lower, xmax = upper), orientation = "y",
                width = .16, colour = blue) +
  geom_point(size = 3, colour = blue) +
  scale_x_log10() +
  labs(title = "Adjusted income odds ratios",
       subtitle = "Reference: annual household income of $75,000 or more",
       x = "Odds ratio (log scale)", y = "Annual household income",
       caption = "Age categories, a three-degree-of-freedom BMI spline and sex are included.\nModel-based 95% intervals; an odds ratio is not a probability ratio.")
save_plot("05-income-odds-ratios", p_or)
bmi_nd <- data.frame(BMI = seq(15, 50, length.out = 160),
                     Income = factor("8", levels = levels(train$Income)),
                     Age = factor("50-54", levels = levels(train$Age)),
                     Sex = factor("Female", levels = levels(train$Sex)))
bmi_pred <- predict(adjusted, newdata = bmi_nd, type = "link", se.fit = TRUE)
bmi_nd$Probability <- plogis(bmi_pred$fit)
bmi_nd$lower <- plogis(bmi_pred$fit - 1.96 * bmi_pred$se.fit)
bmi_nd$upper <- plogis(bmi_pred$fit + 1.96 * bmi_pred$se.fit)
p_bmi <- ggplot(bmi_nd, aes(x = BMI, y = Probability)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = "#D6EAF0") +
  geom_line(colour = blue, linewidth = 1) +
  scale_y_continuous(labels = percent_axis) +
  labs(title = "Why BMI is allowed a curved association",
       subtitle = "Example profile: female, age 50-54, household income $75,000 or more",
       x = "Body mass index", y = "Fitted probability",
       caption = "Model illustration with 95% intervals; it is not an individual clinical risk assessment.")
save_plot("06-bmi-model-shape", p_bmi)
roc_groups <- data.frame(Prediction = pred_adj, Positive = test$Diabetes,
                         Negative = 1 - test$Diabetes) %>%
  group_by(Prediction) %>%
  summarise(Positive = sum(Positive), Negative = sum(Negative), .groups = "drop") %>%
  arrange(desc(Prediction))
roc <- data.frame(FPR = c(0, cumsum(roc_groups$Negative) / sum(1 - test$Diabetes)),
                  TPR = c(0, cumsum(roc_groups$Positive) / sum(test$Diabetes)))
p_roc <- ggplot(roc, aes(x = FPR, y = TPR)) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, colour = muted) +
  geom_line(colour = blue, linewidth = .9) + coord_equal() +
  labs(title = "Ranking performance on the test sample",
       subtitle = paste0("AUC = ", num(metrics$AUC[3], 3)),
       x = "False positive rate", y = "True positive rate",
       caption = "AUC assesses ranking across thresholds; it does not establish clinical usefulness.")
save_plot("07-test-roc", p_roc, width = 7, height = 5.7)
dir.create("figures/slides", showWarnings = FALSE)
save_plot("slides/observed-income",
          p_raw + labs(title = NULL, subtitle = NULL, caption = NULL),
          width = 9.4, height = 4.8)
save_plot("slides/adjusted-income",
          p_adj + labs(title = NULL, subtitle = NULL, caption = NULL),
          width = 9.4, height = 4.9)
save_plot("slides/calibration",
          p_cal + labs(title = NULL, subtitle = NULL, caption = NULL),
          width = 8.5, height = 5)
save_plot("slides/odds-ratios",
          p_or + labs(title = NULL, subtitle = NULL, caption = NULL),
          width = 9.4, height = 4.8)
save_plot("slides/bmi-shape",
          p_bmi + labs(title = NULL, subtitle = NULL, caption = NULL),
          width = 9.4, height = 4.8)
result <- list(
  audit = audit, train_n = nrow(train), test_n = nrow(test),
  train_cases = sum(train$Diabetes), test_cases = sum(test$Diabetes),
  raw_income = raw_income, standardised = standardised,
  odds_ratios = ors, gap = gap, metrics = metrics,
  calibration = calibration, sensitivity = sensitivity, label_audit = label_audit,
  calibration_intercept = unname(coef(cal_intercept)[1]),
  calibration_slope = unname(coef(cal_slope)[2]),
  model_formula = deparse(formula(adjusted)),
  model_converged = adjusted$converged, model_rank = adjusted$rank,
  train_aic = data.frame(Model = names(fits), AIC = vapply(fits, AIC, numeric(1))),
  coefficient_table = coefficients,
  primary_or_low = odds_ratios(adjusted)[odds_ratios(adjusted)$IncomeCode == 1, ],
  acquisition_date = "2026-10-24",
  analysis_source_sha256 = digest::digest(
    paste(readLines("R/analysis.R", warn = FALSE), collapse = "\n"),
    algo = "sha256", serialize = FALSE),
  seed = 20261024)
saveRDS(result, "results/analysis.rds")
jsonlite::write_json(result, "results/analysis.json", pretty = TRUE,
                     auto_unbox = TRUE, digits = 10)
writeLines(capture.output(sessionInfo()), "results/session-info.txt")
message("Analysis complete.")
print(result$metrics)
print(result$gap)
print(result$sensitivity)
