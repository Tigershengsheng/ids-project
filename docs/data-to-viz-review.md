# Figure review prompted by Quiz 7

Review date: 6 November 2026. Statistical analysis date: 5 November 2026.

The user reports that course Quiz Question 7 recommended exploring Data to Viz. That recommendation prompted this check; it is not a new compulsory project requirement or marking criterion. The website pages below were actually consulted. The Quiz 7 question itself was not independently inspected in this revision. First-person text is a draft describing real choices and changes, for the group to review; it does not invent a group meeting or audience testing.

## What we checked and changed

| Location | What we wanted to communicate | Advice actually consulted | Our change or reason for retaining the figure |
|---|---|---|---|
| Slide 2: recorded outcomes | Keep Graduate, Enrolled and Dropout visible | Zero baseline for bar lengths [1] | Retained existing count bars, zero baseline and count/percentage labels. No change to the data or outcome definition. |
| Slide 3: entry profiles | Compare typical values and spread, showing overlap | Boxes hide sample size and some distribution detail [2] | Retained boxplots; added training counts under every outcome in both panels: 1,324, 476, 852. Kept separate labelled units. We do not claim to show full distribution shape. |
| Slide 5: threshold curves | Show how rates change with numerical threshold | Distinguish line/bar purposes [1]; consider colour-blind readers [3] | Retained full 0-100% scale; made all three line patterns distinct. Kept threshold 0.31, the same validation grid and illustrative 70% target. |
| Slide 7: group rates | Compare rates with their supporting denominators and uncertainty | Show sample size [3]; state what error bars represent [4] | Added n beside all ten points, calculated from the correct denominator. Added female circles / male triangles. Explicitly labelled pointwise 95% percentile bootstrap intervals conditional on the fixed model and threshold, rather than SD. |
| Slide 12: group gaps | Compare two groups directly | State the interval metric [4] | Retained existing male-minus-female gap plot and zero line. Notes distinguish its pointwise intervals from simultaneous fairness claims. |
| Slide 13: bootstrap distribution | Show where the existing gap interval comes from | No additional bin-width source used | Retained original 35 bins and stored percentile limits. No trial of alternative bin widths is claimed. |
| Slide 14: calibration backup | Compare probability summaries separately from binary warnings | Colour caveats [3] | Added consistent group shapes, kept point size for n and n < 30 omission, and stated that no intervals are plotted. This remains descriptive, not a group-calibration finding. |
| Slide 18: course composition | Compare each group's course mix | Deliberate category ordering [5]; zero-based bars [1] | Sorted six named courses by pooled training count; kept Other courses last. Added training group totals to the legend. Bar lengths remain proportions within each group. |

Colour review: following the user's request for a launch-style visual redesign, all eight figures now use a dark background with readable light labels. Purple and teal have been brightened to lavender and mint, consistently across group charts. Shape/line cues remain; we do not claim the palette is accessible to every viewer. Outcome categories keep their labels and use muted grey, gold and coral. No accessibility certification or audience experiment is claimed.

## Visual redesign requested during the review

The user asked for a more distinctive, Apple-keynote-like presentation. This is a presentation design preference, not advice attributed to Data to Viz. We rebuilt the cover, used large takeaway headlines, replaced the partition table with three labelled stages, and highlighted the actual trade-off (+107 identified records / +177 false warnings relative to threshold 0.50). Slide 7 highlights the two missed-dropout rates while retaining all five rate rows, denominators and intervals. Slide 8 gives human review and validation clear visual priority. Decorative cover rings encode no data. No Apple assets or endorsement are implied. The numerical analysis remains unchanged. The later PDF delivery revision adds the boxplot/sample-size reasoning to the spoken paragraph for slide 3 while retaining the 635-word total.

## Denominators now shown on slide 7

| Rate | Female n | Male n | Who is counted in n? |
|---|---:|---:|---|
| Warning rate | 575 | 314 | All test students in the group |
| False-positive rate | 431 | 173 | Students without a recorded dropout |
| False-negative rate | 144 | 141 | Students with a recorded dropout |
| Positive predictive value | 218 | 191 | Students receiving a warning |
| Dropout among unflagged (1-NPV) | 357 | 123 | Students without a warning |

Values come from the frozen confusion counts. The R figure script independently checks all ten numerators/denominators against the stored rates. A smaller denominator can contribute to wider uncertainty; interval width also depends on the rate and resampled data, not n alone.

## How the revision appears in the presentation

Slide 3 briefly acknowledges Quiz 7's recommended resource. Slide 9 lists the actual pages. Longer first-person explanations sit beside the corresponding slides in speaker-notes.html and in presenter notes where relevant. The current word count is recorded in results/script-timing.json; the later narrative revision includes the main transitions directly. Preparation notes do not add to the scheduled talk. No actual human rehearsal has been performed by producing these files.

## Reproducibility and limits

R/analysis.R, the raw CSV, fitted models, partitions, predictions, threshold, bootstrap replicates and numerical result files are preserved. R/refresh_figures.R reads those outputs and redraws all eight figures when presentation.Rmd is knitted. It does not fit, tune or resample. The chart types remain bars, boxplots, lines, points with intervals and a histogram. The main talk is still eight slides, followed by sources and nine backup slides.

The error-bar article's informal wording about CI probability is not adopted; the project uses a repeated-sampling interpretation and conditional percentile bootstrap. We have not established how a real audience would respond to these changes. Topic approval, group review, actual rehearsal, repository setup and formal submission remain separate actions.

## Actual webpages consulted

[1] Data to Viz, [To cut or not to cut (the Y axis)](https://www.data-to-viz.com/caveat/cut_y_axis.html).

[2] Data to Viz, [The Boxplot and its pitfalls](https://www.data-to-viz.com/caveat/boxplot.html).

[3] Data to Viz, [Dataviz Caveats](https://www.data-to-viz.com/caveats.html), especially sample-size, colour-blind-reader and consistent-colour reminders.

[4] Data to Viz, [The issue with error bars](https://www.data-to-viz.com/caveat/error_bar.html).

[5] Data to Viz, [Why you should order your data](https://www.data-to-viz.com/caveat/order_data.html).

The [homepage](https://www.data-to-viz.com/) was also consulted for its chart-choice overview. All pages were read on 6 November 2026. These pages supply design prompts, not evidence that our model is accurate or fair.
