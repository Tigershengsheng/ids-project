# Student Dropout Warnings: How Accurate Are They, and Who Gets Missed?

Using 4,424 records from one Portuguese institution, we tested what age, admission grade and course could tell student-support staff at enrolment. The selected warning rule caught 187 of 285 recorded dropouts in the test set. Among recorded dropouts, it missed 64 of 144 female students and 34 of 141 male students.

| Item | Files |
| --- | --- |
| Formal presentation | [HTML](presentation.html) · [Xaringan source](presentation.Rmd) |
| Talk and English rehearsal notes | [PowerPoint](output/powerpoint/Student_Dropout_Presentation.pptx) · [slides PDF](output/reading-pdfs/01_Presentation.pdf) · [script PDF](output/reading-pdfs/02_Speaker_Notes.pdf) |
| Report | [HTML](report.html) · [R Markdown](report.Rmd) |
| Investigation and code walkthrough | [HTML](investigation.html) · [R Markdown](investigation.Rmd) |
| Data and analysis | [data and attribution](data/README.md) · [analysis script](R/analysis.R) · [training-only cross-validation](R/training-course-cv.R) |
| Course and submission checks | [requirements](docs/requirements-checklist.md) · [course map](docs/course-map.md) · [repository access](repository-status.md) |

Open the downloaded HTML in a browser. To reproduce the results, open `student-dropout-final.Rproj` in RStudio. If needed, run `source("R/install.R")`. Run the following from the project root:

```r
source("R/analysis.R")        # rebuild splits, fits, scores and intervals from data/data.csv
source("render_project.R")   # render the slides, report and investigation
source("verify_project.R")   # independently check results against the underlying records
```

## Check-in and team work

For the 27 November check-in we have a four-speaker draft, a threshold comparison and a group-error audit. Our question for the tutor is whether the distinction between a recorded transfer and a student who needs support comes through clearly. **After the meeting:** add who attended, the feedback received and which changes the group agreed to make. Earlier project-kickoff materials remain in the archive and its history.

The team roster in the kick-off workspace lists Tiger, Harry, yingcheLiu and Reiyume. `yingcheliu0723` contributed the report and exploratory Displaced comparison in [5201072](https://github.com/Tigershengsheng/ids-project/commit/52010729291c62865b81816630c45ba2e6679c2c). The [access record](repository-status.md) distinguishes accepted collaborators from pending invitations. One member submits the two HTML files on Gradescope and adds the rest of the group. Every member completes their own peer evaluation.

## Sources

Realinho et al., [UCI dataset 697](https://doi.org/10.24432/C5MC89), CC BY 4.0; [data descriptor](https://doi.org/10.3390/data7110146). The report describes AI assistance in code, source checks, writing and design. The [figure-review notes](docs/data-to-viz-review.md) trace the Quiz 7 recommendation. Figures and all numerical results are generated in R.
