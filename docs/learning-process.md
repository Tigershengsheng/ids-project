# Our course methods and reasons for the analysis

## Methods we applied from the course

We used R to import and inspect the data, treat coded categories as factors, and prepare grouped summaries and plots. We applied the bootstrap idea and the three fairness criteria from our course. We explain each choice in terms of the question it helps answer.

| Course method | What we did and why | 中文说明 |
|---|---|---|
| Import and data types | We read the semicolon-separated file, checked its dimensions and kept the original labels. | 我们先读对数据，再核对行列和标签含义。 |
| Factors | We treated course codes as categories because differences between code numbers have no numerical meaning. | 专业编号只是类别，不能按数字大小解释。 |
| Grouped summaries and joins | We retained row IDs and split assignments so we could trace every rate back to the records it uses. | 我们保留记录编号和划分信息，方便核对每个比例。 |
| Plots and labels | We used boxplots for typical values and spread, and kept group sizes visible. | 我们用课堂图形比较分布，并标清各组人数。 |
| Bootstrap idea | We resampled fixed test predictions within groups to describe uncertainty in the reported rates. | 我们把有放回重抽的原理用于组内指标，同时说明区间的条件。 |
| Fairness criteria | We compared warning rates, both error types and outcomes within both prediction groups. | 我们用三个公平标准回答不同问题，不把一个指标当作完整公平性。 |

The page-level course evidence is in [course-map.md](course-map.md).

## Methods we learned further

Logistic regression, separate validation/test evaluation, threshold selection, AUC and Brier score were less familiar to us. We asked ChatGPT to explain what they measure, checked the documentation, then rewrote and ran the main analysis in R. We checked the outputs against the raw records and saved predictions.

| Supplement | Why we used it | What we need to explain |
|---|---|---|
| Logistic regression | Our outcome is binary and we want estimated probabilities. | Inputs, factor coding and the additive linear terms on the log-odds scale. |
| Training, validation and test records | Fitting, choosing a threshold and evaluating it need different records. | Which decisions use each partition, and why test outcomes do not choose the rule. |
| Threshold rule | A probability needs a decision rule before it becomes a warning. | The illustrative sensitivity target and its false-warning cost. |
| AUC and Brier score | Ranking and probability error add information beyond one threshold's accuracy. | What each score measures and what it cannot establish. |
| Grouped bootstrap implementation | Several rates have different denominators. | Resampling within groups, fixed predictions and the uncertainty omitted by this procedure. |

## Our reasons for key choices

### Slide 2

We kept Enrolled because our question concerns recorded dropout at the stated endpoint. Removing those students would change the population. We therefore call them no recorded dropout at that point, without claiming they graduated.

我们保留Enrolled，是因为研究的是规定终点有没有退学记录。删掉仍在读的学生会改变研究人群，所以我们把他们写成该时点未记录退学，而不是毕业。

### Slide 4

We want an enrolment warning, so a useful predictor must be known at enrolment. Later grades may predict well but answer a different question. We therefore keep a small set of defensible inputs and leave timing-uncertain fields out.

我们想研究入学时预警，因此变量首先要在入学时可知。后来的成绩可能很好用，却回答了另一个问题。所以我们先守住预测时点，再考虑模型能预测多准。

### Slide 5

We use the seventy per cent validation target to make our trade-off explicit. It is our illustrative choice, not university policy. Once it selects a threshold, we keep that rule fixed so the test set can still provide a separate evaluation.

我们用验证集70%的目标，把想多找到退学记录、又要限制误报的取舍说清楚。它是项目中的示例目标。规则确定后就不再用测试结果调整，否则测试集失去独立评价的作用。

### Slide 6

We cannot judge this warning by accuracy alone. Always predicting no dropout already gives 67.9% accuracy, while finding none of the recorded dropouts. We therefore report who is found and how many warnings are false, with separate denominators.

我们不能只按Accuracy判断预警。始终预测不退学，准确率就有67.9%，却找不到任何退学记录。因此我们同时说明找到了多少实际退学记录、发出的预警有多少正确，并分别交代分母。

### Slide 7

We compare missed-dropout rates within actual dropouts, because the groups have different sizes. The relevant comparison is 64/144 against 34/141. We also keep false warnings and both prediction strata, so our fairness discussion covers more than one favourable statistic.

两组人数不同，我们不能只比64人和34人。漏报率应在实际退学的人中计算，也就是64/144和34/141。我们同时保留误报以及预警、未预警两层结果，避免只选一个好看的指标。

## Assistance and responsibility

ChatGPT provided explanations and helped with initial code and text drafts, source checks and slide formatting. We rewrote and ran the main R analysis and checked its outputs. We are responsible for the choices, interpretation and final work.

Supplementary references: official R [stats::glm documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/glm.html) and [Fairness and Machine Learning: classification](https://fairmlbook.org/classification.html). Bootstrap and fairness principles came from the course; some implementation details needed additional learning.
