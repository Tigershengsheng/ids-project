# Our course methods and reasons for the analysis

## Methods we applied from the course

We used R to import and inspect the data, treat coded categories as factors, and prepare grouped summaries and plots. We applied the bootstrap idea and the three fairness criteria from our course. We explain each choice in terms of the question it helps answer.

| Course method | What we did and why |
| --- | --- |
| Import and data types | We read the semicolon-separated file, checked its dimensions and kept the original labels. |
| Factors | We treated course codes as categories because differences between code numbers have no numerical meaning. |
| Grouped summaries and joins | We retained row IDs and split assignments so we could trace every rate back to the records it uses. |
| Plots and labels | We used boxplots for typical values and spread, and kept group sizes visible. |
| Bootstrap idea | We resampled fixed test predictions within groups to describe uncertainty in the reported rates. |
| Fairness criteria | We compared warning rates, both error types and outcomes within both prediction groups. |

The page-level course evidence is in [course-map.md](course-map.md).

## Methods we learned further

Logistic regression, separate validation/test evaluation, threshold selection, AUC and Brier score were less familiar to us. We asked ChatGPT to explain what they measure, checked the documentation, then rewrote and ran the main analysis in R. We checked the outputs against the raw records and saved predictions.

| Supplement | Why we used it | What we need to explain |
| --- | --- | --- |
| Logistic regression | Our outcome is binary and we want estimated probabilities. | Inputs, factor coding and the additive linear terms on the log-odds scale. |
| Training, validation and test records | Fitting, choosing a threshold and evaluating it need different records. | Which decisions use each partition, and why test outcomes do not choose the rule. |
| Threshold rule | A probability needs a decision rule before it becomes a warning. | The illustrative sensitivity target and its false-warning cost. |
| AUC and Brier score | Ranking and probability error add information beyond one threshold's accuracy. | What each score measures and what it cannot establish. |
| Grouped bootstrap implementation | Several rates have different denominators. | Resampling within groups, fixed predictions and the uncertainty omitted by this procedure. |

## Our reasons for key choices

### Slide 2

We kept Enrolled because our question concerns recorded dropout at the stated endpoint. Removing those students would change the population. We therefore call them no recorded dropout at that point, without claiming they graduated.


### Slide 4

We want an enrolment warning, so a useful predictor must be known at enrolment. Later grades may predict well but answer a different question. We therefore keep a small set of defensible inputs and leave timing-uncertain fields out.


### Slide 5

We use the seventy per cent validation target to make our trade-off explicit. It is our illustrative choice, not university policy. Once it selects a threshold, we keep that rule fixed so the test set can still provide a separate evaluation.


### Slide 6

We cannot judge this warning by accuracy alone. Always predicting no dropout already gives 67.9% accuracy, while finding none of the recorded dropouts. We therefore report who is found and how many warnings are false, with separate denominators.


### Slide 7

We compare missed-dropout rates within actual dropouts, because the groups have different sizes. The relevant comparison is 64/144 against 34/141. We also keep false warnings and both prediction strata, so our fairness discussion covers more than one favourable statistic.


## Assistance and responsibility

ChatGPT provided explanations and helped with initial code and text drafts, source checks and slide formatting. We rewrote and ran the main R analysis and checked its outputs. We are responsible for the choices, interpretation and final work.

Supplementary references: official R [stats::glm documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/glm.html) and [Fairness and Machine Learning: classification](https://fairmlbook.org/classification.html). Bootstrap and fairness principles came from the course; some implementation details needed additional learning.

## Reviewing our earlier model after the regression lectures, 11 November

We use the newer regression lectures to review the model we first evaluated on 5 November. The categorical-predictor examples clarify why course is a factor and why its coefficients are comparisons with a reference course. The multiple-predictor examples clarify that a coefficient comparison holds the other included inputs fixed.

The distinction between main effects and interactions helps us state an assumption we had already made: our age and grade effects are additive on the log-odds scale, with no interaction terms. We have not tested a new interaction model or established that the assumption is correct. The model-checking and parsimony material also helps us explain why we examine probabilities and errors, and require evidence before adding complexity.

The logistic-regression link, classification scores and validation rule remain supplementary learning. We distinguish them from the OLS examples in the lectures. The specific checks, source pages and boundaries are recorded in regression-course-update.md.
