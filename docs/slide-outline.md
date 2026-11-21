# Slide logic and speaking plan

The main script is 596 words, approximately six minutes at 100 words per minute before pauses and handovers. Rehearse as a group to measure the actual timing.

| Slide | Core information | Why the next slide follows | Speaker | Words; seconds at 100 wpm |
|---|---|---|---|---|
| 1. Research question | From enrolment information to prediction and the distribution of errors. | Define what a dropout record means. | Speaker 1 | 56; 34 |
| 2. Define the outcome | 4,424 records; the normal course endpoint; Enrolled retained; transfers included. | Inspect the available entry information. | Speaker 1 | 82; 49 |
| 3. Training-only EDA | Age and grade distributions overlap; sample sizes remain visible. | Overlap motivates a model and an independent test. | Speaker 2 | 63; 38 |
| 4. Fit, choose, test | Categorical course; additive log-odds without interactions; timing exclusions and three data partitions. | A probability needs a warning threshold. | Speaker 2 | 87; 52 |
| 5. Validation decision | 0.31 finds 200/284 validation dropouts; a fixed illustrative 70% target. | Check sensitivity, precision and costs on unseen test records. | Speaker 3 | 59; 35 |
| 6. Overall test performance | Sensitivity, precision and accuracy at 0.31. Errors at both cutoffs and the ROC show what changes when the cutoff moves. | 98 records are still missed. Who was more likely to be missed at 0.31? | Speaker 3 | 75; 45 |
| 7. Group audit | 64/144 female and 34/141 male dropouts missed; five rates cover all three fairness criteria. | Observed error differences inform requirements before real use. | Speaker 4 | 91; 55 |
| 8. Conclusion | The exploratory Displaced comparison and the checks needed before real use. | Take questions using the Q&A. | Speaker 4 | 83; 50 |

## Learning and evidence boundaries

We applied course methods to the data summaries, plots, bootstrap and fairness comparisons. For unfamiliar methods, we asked ChatGPT for explanations, checked documentation, then rewrote and ran the main R analysis. ChatGPT also assisted initial code and text drafts, source checks and slide formatting. Our reasons for key choices are in learning-process.md; course evidence is in course-map.md.

Slide 9 lists sources. The supplied brief suggests approximately seven minutes of speaking. The main presentation has eight slides and four speaking parts. The report and the speaker Q&A hold the technical details.

The 11 November regression-lecture review clarifies the fixed model assumptions and adapts model checking to a binary outcome.

## 20 November revision

After reviewing Lab 08, we put the ROC next to the warning-error counts on slide 6. Its closing question leads from the 98 missed cases to the two group rates on slide 7. Slide 7 gives the gap interval. Slide 8 mentions the Displaced comparison as an exploratory finding.
