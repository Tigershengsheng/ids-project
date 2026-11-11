# Regression lecture review, 11 November 2026

The model was first evaluated on 5 November. This later review connects it to the two newly supplied IDS lectures and clarifies assumptions. It introduces no new model, tuning decision or statistical result.

| Lecture evidence | Connection to the existing project | Boundary |
| --- | --- | --- |
| Introducing linear models, pp. 22-28, 38-39 | Distinguish the response, predictors, fitted values and remaining variation; retain non-causal interpretation and limits of generalisation | A fitted association does not establish an intervention effect |
| Introducing linear models, pp. 48-54 | Course codes are categorical; coefficients compare a course with its reference category | Code numbers are not quantities or an ordering |
| Model checking and multiple linear regression, pp. 24-38 | Age, admission grade and course enter together; coefficient comparisons hold other included predictors fixed | Conditioning on included variables does not remove all confounding |
| Model checking and multiple linear regression, pp. 39-54 | State the current no-interaction assumption explicitly | Additivity is on the log-odds scale, not necessarily the probability scale; no interaction model was fitted |
| Model checking and multiple linear regression, pp. 6-12 | Check the adequacy of predictions, not only whether code runs | Binary probabilities need suitable checks; do not require an OLS residual cloud |
| Model checking and multiple linear regression, pp. 57-63 | Justify complexity through useful evidence and interpretability | Ordinary/adjusted OLS R-squared is not classification accuracy; our small model is not claimed optimal |

## What the fixed model assumes

The R formula remains `dropout ~ age10 + admission10 + course`, fitted with `glm(..., family=binomial())`. Age and admission grade are divided by ten; course is an unordered factor. The model is linear and additive on the log-odds scale. The age association is common across courses on that scale, as is the admission-grade association. These assumptions are stated, not certified by the existing results.

An interaction such as age10:course would allow the age association to vary by course. That model has not been fitted here. Any later comparison should be developed within training/validation data, with the parameter count and small course groups considered. Already-viewed test performance must not become a repeated selection criterion presented as a fresh independent evaluation.

## Checks actually available

The project has a baseline, distinct evaluation partitions, held-out probability scores, warning counts, gender-group rates and pointwise conditional bootstrap intervals. The calibration figure compares average predicted probabilities with observed dropout proportions in common bands. Small bins are omitted from display and no calibration intervals are shown. It is a limited descriptive check, not proof of calibration, sufficiency or the correct functional form.

AUC concerns ranking; Brier score concerns squared probability error; calibration concerns agreement between probabilities and observed proportions; threshold metrics concern warnings. These checks answer different questions. The OLS R-squared and log(price) transformation in the lectures are not substituted for logistic classification evaluation.

## Revised locations

- Slide 4 and its spoken block: categorical inputs and additive log-odds assumptions.
- Slide 9: references to the two lectures.
- Slide 14: explanation of the descriptive probability check.
- Slide 17: course foundations, later lecture connections and supplementary methods.
- Speaker notes: conditional coefficient interpretation, interactions, model checking, metric choice and limits.
- Course map and learning-process notes: corrected coverage and the actual chronology of the review.

The lectures are identified by their titles and PDF pages. They remain in the user's course materials and are not redistributed in the public project repository. A private Chinese learning guide is provided separately from the English professor-facing files.
