# Student dropout warnings

**How accurate are enrolment-time warnings, and who gets missed?**

Current IDS group project: enrolment-time prediction of recorded dropout and an audit of group error patterns. The repository is public. Updated 11 November 2026.

## Open the current work

| Purpose | File |
| --- | --- |
| Presentation in the course's HTML format | [presentation.html](presentation.html) |
| Reproducible presentation source | [presentation.Rmd](presentation.Rmd) |
| Editable PowerPoint | [Student_Dropout_Presentation.pptx](output/powerpoint/Student_Dropout_Presentation.pptx) |
| Presentation PDF | [01_Presentation.pdf](output/reading-pdfs/01_Presentation.pdf) |
| English speaking script and Q&A | [02_Speaker_Notes.pdf](output/reading-pdfs/02_Speaker_Notes.pdf) |
| Working research notebook | [investigation.Rmd](investigation.Rmd), [investigation.html](investigation.html) |
| Complete statistical implementation | [R/analysis.R](R/analysis.R) |
| Raw UCI data and attribution | [data/data.csv](data/data.csv), [data/README.md](data/README.md) |
| Decisions, course links and learning process | [analysis plan](docs/analysis-plan.md), [course map](docs/course-map.md), [learning process](docs/learning-process.md) |
| Numerical checks | [verify_project.R](verify_project.R), [36-check results](results/verification.txt) |
| Access and outstanding deliverables | [repository-status.md](repository-status.md) |

GitHub may display HTML source rather than run the presentation. Download the repository using **Code > Download ZIP**, extract it and open `presentation.html` in a browser, or use the PDF. For reproduction, open `student-dropout-final.Rproj` in RStudio.

## Two people uploading to the same repository

`Tigershengsheng` owns this repository. `yingcheliu0723` has a read/write invitation pending acceptance. Sign in as that account and [accept the repository invitation](https://github.com/Tigershengsheng/ids-project/invitations). Then both accounts can contribute their actual changes to this same project.

In each person's local clone: pull the latest changes before editing, make and knit the relevant changes, then commit and push under that person's own account. The public setting lets everyone read/download; it does not give everyone permission to push. Source files and HTML outputs should be kept together.

The course brief distinguishes this collaboration from official submission: one member submits the presentation/report to Gradescope and adds the rest of the group. This repository upload is not that submission.

## Research design

The source contains 4,424 student records from one Portuguese institution. Dropout is the recorded administrative outcome at the normal course endpoint, including changes of course or institution. Graduate and Enrolled are retained as no recorded Dropout at that endpoint; Enrolled is not described as graduated. A separate resolved-outcome check is reported.

The primary model uses enrolment age, admission grade and course as a factor. Later-semester and timing-uncertain information is excluded. Training fits the model, validation selects a shared threshold using an illustrative sensitivity target, and the held-out test set evaluates the frozen rule. Recorded gender is used for auditing, with a separately reported comparison model.

The presentation compares missed dropouts and false warnings at thresholds 0.31 and 0.50 by recorded gender and, as an exploratory comparison, by Displaced status. Both comparisons use the original held-out model scores. These patterns do not establish causation, external validity or an effect of offering support.

## Reproduce in RStudio

1. Download/clone the repository and open `student-dropout-final.Rproj`.
2. If packages are missing, run `source("R/install.R")` once.
3. Run `source("render_project.R")` to render the presentation, report draft, investigation and companion documents. Saved results are reused only when their data/source/design fingerprints match.
4. Knit `investigation.Rmd` for the working notebook.
5. Run `source("verify_project.R")` for the independent numerical checks.

The statistical analysis and analytical figures use R. Package versions are recorded in `results/session-info.txt`; Pandoc is supplied by RStudio. No Windows package library or saved workspace is committed. Export helpers under `tools/` prepare PDF/PowerPoint versions; the formal R/HTML presentation does not require those optional export tools.

## Group and submission status

The presentation and supporting analysis are prepared. The report draft is in `report.Rmd` and `report.html`. Add team member names, review the analysis and complete the GenAI disclosure before submission. Uploading these files to GitHub is not a Gradescope submission. Topic feasibility confirmation, actual check-in notes, live rehearsal, peer evaluation and official submission must be completed and recorded by the group.

The group listed in the kick-off workspace is Tiger (`Tigershengsheng`), Harry (`HarryPeng725`), yingcheLiu (`yingcheliu0723`) and Reiyume (`ReiyumEe`). This upload does not establish equal contributions, accepted invitations or rehearsal. See the current access status below.

Earlier Lab 04 files and Seoul Bike candidate material are retained for continuity. Previous versions of replaced documents are in `archive/project-kickoff/` and in Git history; they are not the current research topic. Earlier check-in meetings have not been invented or reconstructed.

## Sources and assistance

Data: Realinho et al., UCI 697, [DOI 10.24432/C5MC89](https://doi.org/10.24432/C5MC89), CC BY 4.0. Original descriptor: [Realinho et al. (2022), Data 7, 146](https://doi.org/10.3390/data7110146). Full source notes and variable timing decisions are included under `docs/`.

We used our course methods for data handling, plots, bootstrap ideas and fairness comparisons. For unfamiliar methods, we asked ChatGPT for explanations and checked documentation, then rewrote and ran the main R analysis and checked its outputs. ChatGPT also helped with initial code and text drafts, source checks and slide formatting. R generated all statistical results. Our first-person reasons for key choices are in `docs/learning-process.md` and in the speaker notes; the English script PDF now includes a separate preparation page for them.

The 8 November presentation revision clarifies the accuracy baseline, synchronises the eight spoken blocks and removes repeated preparation text. The fixed statistical results are retained. Review tools and their sources are recorded in `docs/revision-review.md`.

The 11 November course review connects the fixed model to the two regression lectures, clarifies the additive log-odds assumption and expands the probability-checking and Q&A explanations. See `docs/regression-course-update.md`. The model, threshold and numerical results are unchanged.
