---
title: "Presentation script and questions"
subtitle: "Suggested four-person allocation; main talk approximately seven minutes"
date: "24 October 2026"
---

## How to use this script

Slides 1-8 form the main talk. Slide 9 lists sources; slides 10-13 are backups for questions.
The allocation below is a suggestion for the group to agree, not a record of who has already contributed.
Aim for roughly seven minutes of speaking plus time for questions. Practise aloud with the actual slides.

## Tiger: slides 1-2, about 90 seconds

Our project asks whether reported diabetes differs across household income groups after accounting for age and body mass index. We also include sex in the adjustment. We chose this question because an overall average can hide important differences between groups, but a direct income comparison may also reflect differences in age or body size.

We used a cleaned extract of the 2015 CDC BRFSS survey, available through UCI. It contains 253,680 adult responses and 21 indicators. This is survey information, not a clinical experiment or a set of blood test results.

An important preparation step was checking the outcome. The website says that the binary positive class includes prediabetes. However, when we compared every row with the original three-category file, the positive class matched diabetes only. We therefore use that verified definition and later check what happens when prediabetes records are excluded.

The extract has no survey weights. Our results describe this selected sample, rather than national prevalence. We split the records into about eighty per cent for training and twenty per cent for testing.

## Harry: slides 3-4, about 95 seconds

This first figure shows the observed diabetes proportions in the training sample. The lowest income group is at about 24.3 per cent, compared with 8.0 per cent in the highest income group. The raw difference is about 16.3 percentage points.

The pattern is not perfectly ordered. The second-lowest income band has the highest observed proportion. We should not claim that every rise in income gives a lower raw proportion.

The income groups also differ in age and BMI. For example, about 41 per cent of the lowest income group are aged sixty or older, compared with about 36 per cent of the highest. Their mean BMI values are also different.

We used logistic regression to make an adjusted comparison. Age and income were treated as categories. We allowed BMI a smooth curve rather than forcing a straight-line relationship. We then compared the income groups using the same age, BMI and sex distribution. This helps describe the income difference after considering these measured characteristics. It does not turn the comparison into a causal experiment.

## yingcheLiu: slides 5-6, about 110 seconds

After adjustment, the standardised proportions are about 23.7 per cent for the lowest income band and 9.4 per cent for the highest. The difference is 14.3 percentage points, with a model-based ninety-five per cent interval from about 13.4 to 15.2 points.

The gap is smaller than the raw comparison, but still substantial. The adjusted odds ratio is about 3.39. That is an odds ratio, not a statement that probability is 3.39 times higher. The percentage-point comparison is easier to interpret directly.

We also evaluated the models on the test sample, which was not used for fitting. Adding income increased AUC from about 0.750 to 0.768 and slightly improved probability prediction error.

However, accuracy alone gives a misleading impression. Simply predicting no diabetes for everyone already achieves about eighty-six per cent accuracy, because most records are negative. At a threshold of 0.5, our adjusted model identifies only about 6.5 per cent of the positive cases.

So the model gives useful evidence about group differences, but these results do not establish an effective screening rule. Predicting a survey label in held-out records is also different from predicting future diabetes or diagnosing a patient.

## Reiyume: slides 7-8, about 100 seconds

We checked three modelling and coding choices. We replaced the curved BMI term with a linear term, excluded prediabetes records, and excluded BMI values above sixty. The lowest versus highest income odds ratio stayed between about 3.37 and 3.52, compared with 3.39 in the primary model.

These checks make us more confident that the association is not just a consequence of those particular choices. They do not remove all confounding or sampling bias.

Our main conclusion is that a substantial income difference remains after accounting for the measured age, BMI and sex variables. That is a reason to investigate socioeconomic differences further when discussing accessible health education and support.

There are clear limits. Diabetes may itself affect income, and reported diagnosis can depend on access to care. The cleaned extract has no survey design variables, and the data are from 2015. We cannot use these percentages as current national rates or decide which intervention would reduce the gap.

A useful next step would be to analyse newer survey data with the original weights and design, and examine whether the pattern differs across age groups. Thank you.

## Questions you should be ready to answer

### Why this question rather than predicting diabetes with every variable?

We wanted a focused question with an interpretable comparison. Adding many medical-history and self-rated-health variables could improve label prediction, but would move away from our income question. Some may also reflect the consequences of an existing diagnosis.

### Why use logistic regression?

The response is binary. Logistic regression gives fitted probabilities between zero and one and lets us compare income categories after including other measured characteristics.

### Why are age and income categorical?

Their numbers are codes. Age 1 means 18-24 years. Income categories are not equally spaced dollar amounts. Using factors avoids treating a one-code increase as the same numerical change everywhere.

### Why include sex as well as age and BMI?

It is an additional recorded characteristic that can differ across income groups. Including it makes the scope of the adjusted comparison explicit. It does not exhaust all potential confounders.

### What does standardisation mean here?

We average the model predictions for each income band over the same empirical distribution of age, BMI and sex. This puts the income groups on a common descriptive basis. It is not a prediction of the consequences of giving somebody a different income.

### Is the 14.3-point gap caused by low income?

No. Cross-sectional associations cannot establish the direction of causation, and unmeasured factors and diagnosis access may influence the comparison.

### Why not use the balanced dataset?

It changes the case proportion. The full dataset is better suited to interpreting the observed sample proportions and average fitted probabilities. We address imbalance with appropriate evaluation metrics rather than interpreting accuracy alone.

### Why does high accuracy coexist with low sensitivity?

Most records are negative. A model can classify most people as negative and appear accurate, while missing nearly all positives. At the fixed 0.5 threshold, that is a serious limitation here.

### Could a different threshold improve sensitivity?

Yes, with a trade-off in false positives. We did not tune a threshold on the test set. Choosing a screening threshold would need a clear use case, appropriate validation and a separate discussion of consequences.

### Why no survey weights?

They are not included in this cleaned extract. We explicitly limit the conclusions to the sample. A population analysis should return to the original BRFSS survey data and its sampling design.

### How did you check the label problem?

We downloaded the publisher's original three-category file, compared all 21 predictor columns row by row, then cross-tabulated its outcome with UCI's binary outcome. Original diabetes maps to one, while prediabetes maps to zero. Backup slide 11 gives the counts.

### Did you remove duplicate rows?

We kept repeated response profiles. Different survey respondents may have the same answers, particularly after age and income are grouped. Without real identifying information, matching answers do not prove duplication.

### Where do the confidence intervals come from?

Observed proportions use Wilson intervals. Adjusted odds ratios use the fitted logistic coefficient covariance. Standardised probabilities use the delta method with the same covariance. These are model-based sample intervals, not survey-design-correct national intervals.

### What is the practical value?

It quantifies an income pattern that persists after specific measured differences are considered. It supports further investigation and discussion of accessible support. It does not establish the best intervention or a clinical decision rule.

### What assistance did you use?

ChatGPT helped plan and draft the code, report and slides. We disclose that assistance. The numerical results come from the supplied R scripts and actual data; do not claim group review or individual work that has not happened.
