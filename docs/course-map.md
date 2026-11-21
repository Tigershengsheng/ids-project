# Course knowledge used in this project

## Additional recommended exploration: Data to Viz

Quiz Question 7 recommended this website, which prompted our figure review. Following that recommendation, the 6 November figure review applies sample-size labels, deliberate ordering, colour-independent markers and explicit interval descriptions. This connects to the visualisation and uncertainty topics below, but the resource is not presented as a compulsory project requirement. Actual URLs, changes and retained choices are recorded in data-to-viz-review.md; first-person explanations appear in the corresponding speaker notes. No additional modelling method was introduced.

Page numbers below refer to PDF pages, not inferred lecture dates. This map distinguishes material actually available in the workspace from supplementary methods. All available PDFs were text-extracted page by page; the task-relevant sections were inspected. The underlying PDFs remain in the user's course folders and are not redistributed in this project.

| Supplied material | Evidence pages | Application | Where to find it |
|---|---|---|---|
| Data Types and Classes | 15-17, 23-27 | Missing values, data frames, factors; course codes are categorical rather than quantities | R/analysis.R data audit; slide 4; study guide |
| Importing_Exporting Data | 3-6, 7-16 | Semicolon-delimited input, explicit decimal point, reproducible column handling and CSV export | Raw read_delim call; results/ CSVs |
| Tidy Data and Data Wrangling | 4, 13-26, 35-36 | One student per row, select/transmute/filter/count/group_by/summarise, helper functions and pipes | R/analysis.R throughout |
| Joining and Organising Data Sets | 3-8, 11-25, 35-41 | Join split assignments by stable profile ID; reshape summaries for plotting | left_join and pivot_longer; split-membership.csv |
| Doing Data Science | 4-8, 26-36 | Predictive rather than causal question; sample limits; conditional proportions; possible composition effects | Slides 1-4, 7-8; course/gender training summaries |
| Visualising data | 5-10, 16, 19-29 | EDA supported by plots, graphics layers, labels, colour and audience respect | Entry-profile boxplots; outcome and threshold plots |
| Types of visualisations | 4-5, 10-22, 28-30 | Match numerical/categorical inputs to boxplots and bars; faceting; histogram for bootstrap estimates | Slides 2–3; saved bootstrap distribution in figures/ |
| Effective Data Visualisation | 5, 9-16 | Readable labels, meaningful colours, consistent ordering, remove redundant elements and iterate | All slides; actual browser/PDF visual check |
| Quantifying uncertainty | 12-15, 21-32, 39, 44-53 | Resample with replacement, recompute differences, use middle 95%; distinguish sampling uncertainty from more repetitions | 5,000 conditional test-record bootstrap replicates; slide 7 and the investigation notebook |
| Ethics in Data Science - Misrepresentation | 6-13, 16-22, 24-25 | Interpret the measured label correctly, avoid causal or population claims, preserve denominators and privacy, reproducibility | Label slide; count table; limitations; aggregate outputs |
| Ethics in Data Science - Algorithmic Bias | 6-8, 16-19, 27, 29 | Bias through measurement/representation/deployment; overfitting concept; Independence, Separation, Sufficiency; disclose assistance honestly | Slides 4, 7–9; group tables in the report |
| Introducing linear models (55 pages) | 22-28, 38-39, 48-54 | Response/predictor distinction, limits of interpretation, reference categories and dummy coding; logistic regression is a separate extension | Slide 4; course coding; speaker notes |
| Model checking and multiple linear regression (66 pages) | 6-12, 24-41, 57-63 | Diagnose fit, interpret multiple inputs conditionally, distinguish main effects/interactions, justify complexity; adapt checking to a binary outcome | Slides 4, 14, 17; assumptions and Q&A |
| Lab 04 - Project kick-off and data viz exercises | 1-2, 4-6 | Group repository/template, variable types, numerical and categorical plots, interpretation | Template adaptation and main figures |
| Lab 05 - Halloween Candies & Data Viz Improvement | 8-12, 14-18 | Grouped counts/proportions, faceting, reshape before graphics, labels and numeric axes | Training summaries, long-form figure data, figure revisions |
| HW 02 - Data Visualisation | 9-14 | Describe distributions, distinguish observation unit, calculate grouped statistics, facet mixed units | Training-only age/grade panels and interpretation |
| Existing lab-01.Rmd and lab-02.Rmd | Exercise headings rather than PDF pages | Practice with wrangling, grouped summaries and joins | Same operations used on the new dataset; previous answers are not imported as results |
| Existing lab-03.Rmd | Section 3.1 and 3.2 | Both infer and base-R bootstrap implementations are present in the available lab | Repeated with-replacement sampling and percentile intervals in the audit |
| Existing lab-04.Rmd and lab-05.Rmd | Exercise headings rather than PDF pages | ggplot choices, denominators, categorical vs numeric axes and substantive interpretation | Analytical figures and study-guide explanations |
| Quiz screenshots in this conversation | No complete standalone quiz file available | Question types, sampling bias, bootstrap intervals, ggplot mappings and project-file roles | Used as supporting learning context, not represented as a complete reviewed quiz bank |

## Classification material supplied after the initial analysis

| Course source | What it teaches | How the project uses it |
| --- | --- | --- |
| Predicting categorical outcomes, PDF pp. 15–23 | Log-odds, logistic regression and predicted probabilities | Binary recorded dropout. Ten-year and ten-point coefficients are interpreted holding the other included variables fixed. |
| Predicting categorical outcomes, PDF pp. 25–30 | Confusion counts, sensitivity, specificity and cutoff trade-offs | The warning rule and its error denominators. Precision uses a different denominator, all issued warnings. |
| Model building, PDF pp. 6, 15–19, 26, 30, 35–44 | Data splitting, probability prediction, factors/dummies, ROC/AUC, workflows and cutoff examples | Hold-out evaluation, ranking and threshold choice. The project uses glm with factor coding for the fitted model. |
| HW03 and Quiz 1–9 in the chat | Model terms, coefficient units, conditioning, extrapolation and R-squared scope | Clear units and baseline, modest claims about other cohorts and explicit separation of OLS and logistic diagnostics. |
| Lab 07, pp. 5, 8, 10–11 | Explain diagnostics and keep written figures linked to R outputs | The notebook uses the actual code and generated estimates. Residual-cloud interpretation stays in its linear-regression context. |
| [Lab 08, pp. 8–11](https://uoeids.github.io/labs/lab-08/lab-08.html) | Fit on training data, evaluate test probabilities with ROC/AUC and compare errors at several cutoffs | Slide 6 shows the ROC from frozen test scores and marks both cutoffs. Slide 7 follows up on who gets missed. |

The initial analysis ran on 5 November. This course review identifies connections to materials supplied later. The exact 60/20/20 stratification and duplicate-profile policy, validation sensitivity target, rank implementation of AUC, Brier score, grouped probability check and conditional bootstrap of multiple fairness gaps are project choices or supplementary implementations. R documentation and the methods notes describe these details.

## Deliberate omissions

There is no meaningful need to force every type of join, dates, every graph geometry, a causal-effect estimator or all available predictors into this analysis. No date/year field is reconstructed from macroeconomic values. No synthetic rebalancing or group-specific thresholds are used merely to improve a score or equalise a table. No Simpson's paradox is claimed from the fact that course compositions differ.

## Transfer of the regression lectures

We use the multiple-predictor and category-coding principles to explain the existing formula. The primary model is additive on the log-odds scale; no interactions are fitted. OLS residual-cloud rules, ordinary/adjusted R-squared and log-transforming a continuous response are not directly substituted for binary probability diagnostics or classification accuracy. The current calibration plot is descriptive; it does not validate all model assumptions. We retain the original results while recording possible development-data checks for a future extension.
