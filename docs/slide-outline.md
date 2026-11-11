# Slide logic and speaking plan

The current main talk is 599 words: about 5.99 minutes at 100 words/minute, before pauses. Its main links are already included; do not add the alternative handovers again. Human rehearsal is still required.

| Slide | Core information | Why the next slide follows | Speaker | Words; seconds at 100 wpm |
|---|---|---|---|---|
| 1. Research question | From enrolment information to prediction and the distribution of errors. | Define what a dropout record means. | Speaker 1 | 56; 34 |
| 2. Define the outcome | 4,424 records; the normal course endpoint; Enrolled retained; transfers included. | Inspect the available entry information. | Speaker 1 | 82; 49 |
| 3. Training-only EDA | Age and grade distributions overlap; sample sizes remain visible. | Overlap motivates a model and an independent test. | Speaker 2 | 63; 38 |
| 4. Fit, choose, test | Categorical course; additive log-odds without interactions; timing exclusions and three data partitions. | A probability needs a warning threshold. | Speaker 2 | 87; 52 |
| 5. Validation decision | 0.31 finds 200/284 validation dropouts; a fixed illustrative 70% target. | Check sensitivity, precision and costs on unseen test records. | Speaker 3 | 59; 35 |
| 6. Overall test performance | Sensitivity 65.6%, precision 45.7%, accuracy 64.0%, denominators, baseline, +107 finds and +177 false warnings. | 98 records are still missed: overall averages do not show which groups bear errors. | Speaker 3 | 85; 51 |
| 7. Group audit | 64/144 female and 34/141 male dropouts missed; five rates cover all three fairness criteria. | Observed error differences inform requirements before real use. | Speaker 4 | 95; 57 |
| 8. Conclusion | Human review, label meaning, support capacity and later-cohort validation; no intervention-effect claim. | Close; use references and backups for questions. | Speaker 4 | 72; 43 |

## Learning and evidence boundaries

We applied course methods to the data summaries, plots, bootstrap and fairness comparisons. For unfamiliar methods, we asked ChatGPT for explanations, checked documentation, then rewrote and ran the main R analysis. ChatGPT also assisted initial code and text drafts, source checks and slide formatting. Our reasons for key choices are in learning-process.md; course evidence is in course-map.md.

Slides 9-18 remain sources and backups. Slide 17 explains course versus supplementary methods in first person. The supplied brief suggests approximately seven minutes of speaking; eight main slides and four speaking parts are our organisational choices, not invented course rules.

The 11 November regression-lecture review clarifies the fixed model assumptions and adapts model checking to a binary outcome. Reference and backup slides do not add material to the timed eight-slide talk.
