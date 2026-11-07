# Our course methods and learning process

We used the following distinction when preparing the analysis and explaining our work. Our first-person account reflects the group's description of its learning and reimplementation. We retain the actual AI assistance with initial drafts, source checks, implementation explanations and slide design.

| Method | Our first-person explanation | 中文说明 | Course evidence or supplement |
|---|---|---|---|
| Data types and factors | We treated course codes as categories rather than numerical distances. | 我们用课堂的因子概念处理专业编码。 | Data Types and Classes, pp.15-17,23-27 |
| Import and data audit | We read the semicolon-separated file and checked its dimensions, labels and unknown encodings. | 我们读取原表，核对行列、标签和未知编码。 | Importing_Exporting Data, pp.3-16 |
| Grouped summaries and joins | We used grouped counts, proportions and joins to keep every record and its split assignment traceable. | 我们按组计数、算比例，并连接划分信息。 | Wrangling and Joining materials |
| Visualisation | We used boxplots, bars, layers and labels to connect the statistical summary with what the audience can see. | 我们用课堂的图形方法解释分布和比较。 | Visualising data; Types; Effective Data Visualisation |
| Bootstrap concept | We used the with-replacement resampling idea from class to describe uncertainty. | 我们用了课堂中有放回重抽和分位数区间的原理。 | Quantifying uncertainty, pp.21-32,39,44-53; lab-03 |
| Three fairness criteria | We compared coverage, errors conditional on actual outcomes, and outcomes conditional on both warning decisions. | 我们分别应用Independence、Separation和完整二分类Sufficiency。 | Algorithmic Bias, pp.16-19 |
| Logistic regression | We were unfamiliar with this model. We used AI explanations and R documentation, then reimplemented and checked the analysis in R. | 我们起初不熟悉逻辑回归，借助AI解释与R文档学习，再重新编写与核对。 | Supplement: official stats::glm documentation |
| Held-out validation and thresholds | We learned why training, validation and test records need different jobs before using a threshold. | 我们补学三份数据的分工及阈值选择，再在R中实现。 | Supplement; no separate modelling lecture supplied |
| AUC and Brier | We learned that ranking, probability error and threshold-based accuracy measure different things. | 我们补学排序、概率误差和分类准确率之间的区别。 | Supplement; explained in the study guide |
| Grouped bootstrap implementation | We needed help translating the course bootstrap idea into grouped resampling of several fixed-prediction metrics. | 原理课堂学过，按组重抽和多指标代码是进一步学习的实现。 | Course principle; supplementary implementation |
| Presentation and helpers | We followed the supplied xaringan template and used AI assistance with formatting, source checks and initial drafts. We are responsible for the final explanation and verification. | 我们沿用老师模板，保留排版、核查来源和初稿中的AI辅助说明。 | Supplied template; implementation support |

Our decision chain is: define the endpoint; inspect entry information; fit and validate; compare sensitivity, precision, accuracy and both error types; ask who bears those errors; interpret group differences and uncertainty; identify what needs checking before any actual use.

References: the page-level course map is in course-map.md. Supplementary methods use official R documentation (https://stat.ethz.ch/R-manual/R-devel/library/stats/html/glm.html) and the classification chapter of Fairness and Machine Learning (https://fairmlbook.org/classification.html). We do not treat all supplementary implementation details as if they had been taught in the supplied slides.
