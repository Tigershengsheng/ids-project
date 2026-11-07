# Course requirements and delivery status

Authority: the exact Final Project PDF supplied by the user, `Final Projects __ Introduction to Data Science (2023).pdf`, 11 PDF pages. The title is retained for identification; it is not treated as evidence that these are obsolete requirements. Any explicit current-course update takes precedence. The supplied document contains an overall allocation of marks, not a detailed 50-point presentation rubric; no additional marking bands are invented.

## Explicit requirements

| Requirement and evidence | This project | Status |
|---|---|---|
| Interesting real-world question using course techniques, pp. 1-2 | Enrolment warning accuracy and group errors, with a support-oriented interpretation | Implemented; group must understand and review |
| Alternative datasets allowed; UCI specifically recommended, p. 5 | UCI 697; official data, metadata and original paper retrieved | Source verified |
| At least 100 rows after missing-value handling; numerical and categorical variables, p. 5 | 4,424 records; age/admission grade numerical, course/recorded gender categorical; no blank/NA cells in source | Verified by R audit; coded unknowns documented separately |
| Course organiser or lecturer should confirm dataset feasibility, p. 5 | Candidate and its boundaries are documented | Pending actual confirmation; not claimed approved |
| Data understanding, appropriate EDA, model and evaluation, pp. 1-3 | Timing audit, training-only EDA, fixed logistic model, validation threshold, held-out results, baseline | Implemented |
| Critique data reliability, validity and methods; cautious interpretation, pp. 2-3 | Administrative departure includes transfers; one historical institution; no individual timestamps or cohort/year field | Explicit in slides and notes |
| Select informative visualisations; clarity and coherence, p. 3 | Eight main slides; R plots with labelled denominators and uncertainty; detailed results in backups | All 18 HTML/PDF pages rendered and reviewed; offline browser has no overflow or missing resources |
| All analysis in R/RStudio, p. 3 | R/analysis.R generates every statistic and analytical figure | Implemented; Python only retrieves/extracts sources and packages/verifies exports |
| Use the project-repository slide template, pp. 6, 8 | Original template archived in docs/course-template; xaringan::moon_reader, 16:9, knitr tables and ggplot workflow retained | Adapted; example content and optional confetti styling replaced |
| Total group slot 10 minutes; suggested 7-minute talk + 2-minute questions, p. 6 | Slides 1-8 are the main talk; references/backups are for consultation | Script timings estimated from words; human rehearsal pending |
| Every member has an opportunity to speak, p. 6 | Suggested four-part allocation; actual speaker names and agreement need group confirmation | Proposed, not a contribution record |
| Explain choices, reasons and findings rather than a chronological account, p. 6 | First-person notes explain decisions actually reflected in the source audit and analysis | Drafted for group review; no invented meetings or feedback |
| Hide presentation code, but retain reproducible source, pp. 6, 10 | Global echo=FALSE; sourced R analysis and complete raw data accompany Rmd | Implemented |
| GitHub collaboration and course-account access, pp. 3, 8-10 | Current R sources, data, presentation and working notebook uploaded to Tigershengsheng/ids-project on 7 November 2026; course-account and member invitations checked | Upload complete; uoeIDS and three member invitations pending acceptance |
| Check-in discussions and feedback, pp. 5-6, 9 | Notes may be recorded after actual attendance | Pending; no tutor feedback fabricated |
| HTML presentation submission, p. 9 | presentation.html is the formal slide format; sharing PDF is supplementary | File prepared, not submitted |
| Approx. 1,500-word report, maximum 1,650; report HTML and repository link, pp. 7, 9 | This task covers the presentation and supporting analysis | Not produced; remains a separate deliverable |
| Peer evaluation and actual contribution, pp. 7-10 | Suggested speaking allocation does not establish contribution or peer scores | Pending each student's real evaluation |

## Stated mark allocation

The supplied document, PDF p. 11, allocates Presentation 50, Report 40, Reproducibility/organisation 5, Second check-in 5. The report and organisation components are adjusted according to the stated peer-assessment formula. This package cannot establish a mark or complete participation requirements.

## Our choices rather than course requirements

- The exact topic, gender comparison, small predictor set and binary endpoint.
- Approximately 60/20/20 splitting and seed 20261105.
- A validation sensitivity goal of 70%, one shared threshold and 5,000 bootstrap replicates.
- The gender-inclusive and Enrolled-exclusion sensitivity checks.
- Eight main slides, four suggested speaking parts and the visual colour scheme.

## Suggestions requiring later judgement

Prospective validation, consultation about support capacity and error costs, more complete gender representation, privacy/access controls before any actual operational use, and review of the reasons behind administrative departures. None is presented as an intervention already shown to work.
