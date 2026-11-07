# Sources and definitions

## Course authority

The user's supplied Final Project PDF and local xaringan template are the authority for this task. The filename's “2023” is only part of its title; it is not used to infer the applicable year. Any explicit current-course update must be checked against this file. The public course website is not used to override it.

## Dataset

Realinho, V., Vieira Martins, M., Machado, J., and Baptista, L. (2021). Predict Students' Dropout and Academic Success. UCI Machine Learning Repository. DOI: https://doi.org/10.24432/C5MC89

- Official page: https://archive.ics.uci.edu/dataset/697/predict+students+dropout+and+academic+success
- Raw download and retrieval hashes are recorded in docs/sources/retrieval.json.
- Source CSV is retained unchanged as data/data.csv. It uses semicolons and decimal points, contains a UTF-8 BOM and a trailing tab in one original header. read_delim(trim_ws=TRUE) handles the header while raw bytes are preserved.
- The downloaded file has 4,424 rows, 36 predictors and one Target column. The paper describes 35 attributes, so the file audit and UCI metadata, rather than the older paper's count, determine the implemented schema. Admission grade and previous-qualification grade are described explicitly by current UCI metadata.
- CC BY 4.0: preserve source attribution. The Python retrieval helper performs no statistical analysis.

## Original data descriptor

Realinho, V., Machado, J., Baptista, L., and Martins, M. V. (2022). Predicting Student Dropout and Academic Success. Data, 7(11), 146. DOI: https://doi.org/10.3390/data7110146

The open original PDF is preserved under docs/sources with a retrieval record. Critical evidence:

- PDF p. 1: field/course or institution changes are considered dropout, independently of timing. This is broader than leaving higher education without a degree.
- PDF p. 2: one Portuguese institution, 17 undergraduate degrees, enrolments from 2008/09 to 2018/19. Sources are administrative/admission systems and PORDATA macroeconomic data.
- PDF p. 3, Table 1: distinguishes enrolment information from first- and second-semester information. Socioeconomic fields appear as their own group; individual observation timestamps are not supplied.
- PDF p. 4: Target is assigned at the normal duration of the course, three years except Nursing at four years.
- PDF p. 16, Table A8: Gender uses 0=female and 1=male. These are the release's binary recorded categories, not a complete account of gender identity.

No consent, ethical approval, contemporary representativeness, prospective validation or intervention success is inferred merely from open availability.

## Methods added to the supplied course material

- Official R documentation for glm: https://stat.ethz.ch/R-manual/R-devel/library/stats/html/glm.html
- Official R binomial-family documentation: https://stat.ethz.ch/R-manual/R-devel/library/stats/html/family.html
- Barocas, Hardt and Narayanan, Fairness and Machine Learning, Classification chapter: https://fairmlbook.org/classification.html
- Xie, R Markdown: The Definitive Guide, xaringan: https://bookdown.org/yihui/rmarkdown/xaringan.html

Fairness definitions are taken from the user's Algorithmic Bias slides, p. 17, and checked against the book. Binary-label sufficiency conditions on both R=1 and R=0; calibrated probabilities and thresholded labels are not interchangeable. Fairness incompatibility statements need assumptions; perfect prediction does not establish demographic parity when underlying outcome rates differ. The project does not claim a universal theorem without its conditions.

## Figure-review sources, accessed 6 November 2026

The user reports that course Quiz Question 7 recommended exploring Data to Viz. This prompted the review; it is not a new compulsory project requirement. The Quiz 7 wording has not been independently inspected in this revision. The actual pages consulted were:

- https://www.data-to-viz.com/ — chart-choice overview.
- https://www.data-to-viz.com/caveat/boxplot.html — hidden sample sizes and distribution details.
- https://www.data-to-viz.com/caveat/error_bar.html — distinguish dispersion from uncertainty and identify what intervals mean.
- https://www.data-to-viz.com/caveat/cut_y_axis.html — zero baselines for bar lengths; different purposes of line graphs.
- https://www.data-to-viz.com/caveat/order_data.html — deliberate category ordering.
- https://www.data-to-viz.com/caveats.html — sample-size labels, intentional/consistent colours and consideration of colour-blind readers.

The error-bar article includes an informal probability description of confidence intervals; this project retains the course's repeated-sampling interpretation and its own percentile bootstrap method. The website supplies design advice, not validation of the model or fairness conclusions. Its general preference for raw observations does not replace uncertainty intervals for the binary rates compared here. Detailed decisions and changed slide locations are in data-to-viz-review.md.

## Assistance and outstanding review

ChatGPT helped retrieve/check sources, write R code, draft the slides and prepare explanations. R generated all statistical results and analytical charts. The group must review the analysis, replace wording it cannot defend, confirm speakers and understand the code. No actual group discussion, tutor approval, rehearsal, peer evaluation or submission is invented.
