# Analysis plan

Plan recorded on 5 November 2026 before model evaluation in this project. This is a local analysis plan, not an external preregistration. Published class counts and source documentation were already known. An initial four-input fitting attempt revealed exact rank deficiency: in training data, attendance regime was deterministic within course. Before any validation scoring or test evaluation, attendance was removed from the formula. The cross-tabulation is saved in results/training-course-attendance.csv.

## Question and outcome

Can information available at enrolment distinguish students recorded as Dropout by the normal end of their course? Does a common warning rule have different selection and error rates for the recorded female and male groups?

The primary binary response is 1 for Dropout and 0 for Graduate or Enrolled, assessed at the source's normal course endpoint (usually three years, four for Nursing). Zero means no recorded dropout at that endpoint; it does not mean graduated or will never leave. All three original labels are retained. A separate Dropout-versus-Graduate sensitivity analysis changes the estimand and explicitly excludes Enrolled; it cannot replace the primary result just because it looks better.

The original paper's definition includes changes of institution or course. Thus this is an administrative departure label, not a verified measure of abandoning higher education or of needing support.

## Inputs and timing

Primary model: enrolment age, admission grade, and course as a factor. These form a deliberately small, interpretable enrolment model. Attendance regime is excluded after the training-only redundancy check described above. Recorded gender is reserved for the primary audit, not used as a primary predictor. A pre-specified gender-inclusive comparison tests whether its omission by itself resolves group differences; the primary model is not selected using the test set.

Exclude all twelve semester-end academic variables. Exclude debt, fee-payment and scholarship status because the public release does not provide individual measurement timestamps sufficient to establish baseline availability. Exclude macroeconomic indicators because they can act as cohort proxies and no enrolment-year field is supplied. Other baseline variables are documented but omitted for scope and interpretability, not because a test-set feature search rejected them.

## Partition, fitting and warning rule

Use seed 20261105. Allocate approximately 60% training, 20% validation, 20% test within each original outcome-by-recorded-gender stratum. Fit only on the training portion. Use no oversampling and no test-driven model or feature selection. Fit an intercept-only probability baseline and an unweighted binomial logistic model with the fixed inputs above. Treat course codes as unordered categories.

Choose one common threshold on the validation set: among thresholds 0.05 to 0.80 in steps of 0.01 attaining at least 70% sensitivity, choose the highest specificity, with the higher threshold breaking exact ties. If none attains the target, use the lowest candidate threshold and explicitly report target failure. The 70% goal is an illustrative analytical choice, not a policy agreed by a university. It prioritises finding recorded departures but does not prescribe a real support capacity or an optimal cost trade-off.

Keep the training fit frozen after threshold selection; do not refit on validation before testing. Evaluate the same fixed model at 0.5 as a pre-specified threshold comparison. Fit a gender-inclusive comparison on the same training rows, and evaluate it at the primary model's common selected threshold. Neither test results nor fairness gaps determine the final model or threshold.

## Evaluation and uncertainty

Report class proportions, confusion counts, AUC, Brier score, accuracy, sensitivity, specificity, precision (PPV), NPV, warning rate and false omission rate. Define the positive class and denominators next to tables. Retain actual counts for every rate.

On held-out predictions at the fixed validation-selected threshold, compare by recorded gender:

- Independence: warning rate.
- Separation: FPR and FNR (TPR is one minus FNR).
- Binary-label sufficiency: PPV and NPV, or equivalently the actual-positive rate within both predicted classes.

Use 5,000 ordinary nonparametric bootstrap replicates, resampling held-out student records independently within each recorded gender group. Compute pointwise percentile intervals for group metrics and male-minus-female gaps. These intervals condition on the fitted model, partition and chosen threshold; they do not include refitting uncertainty, historical cohort clustering, external validity or multiple-comparison correction. They are descriptive evidence, not tests that certify equality or discrimination. A separate binned probability-calibration figure uses common score bands and is not labelled proof of binary sufficiency.

## Limitations and boundaries

One Portuguese institution and historical enrolment cohorts; no prospective validation at Edinburgh. No cohort/year column in the released predictors, so this random hold-out cannot establish performance on later cohorts. Binary recorded gender is an administrative variable and cannot represent every gender identity. Do not infer causes of departure, scholarship effects, intervention effectiveness or actual fairness of a deployed decision system. No group-specific thresholds are introduced to force equal metrics.

## Outstanding course actions

The supplied brief permits alternative datasets from sources including UCI and asks for feasibility confirmation with the course organiser or lecturer. That confirmation, group review, actual rehearsal, check-in attendance, repository collaboration and any submission remain human actions; none is recorded as completed by this analysis.
