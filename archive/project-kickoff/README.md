# IDS project: kick-off workspace

**Status:** Lab 04 code, plots and initial exploration prepared and checked. Seoul Bike Sharing Demand is a
candidate for discussion; it has not yet been agreed as the group's final topic.

Private project repository: https://github.com/Tigershengsheng/ids-project

## Group

| Member | GitHub |
| --- | --- |
| Tiger | Tigershengsheng |
| Harry | HarryPeng725 |
| yingcheLiu | yingcheliu0723 |
| Reiyume | ReiyumEe |

The user confirmed that the four-person Lab 03 group continues for this project.

## Open these first

- [Star Wars exercises: rendered answers](lab-04.html) — all eight optional exercises.
- [Project exploration: rendered draft](investigation.html) — data checks and three initial plots.
- [Chinese reading guide](study-guide.html) — where to open files and what the code does.
- [Data source and dictionary](data/README.md).

The R Markdown sources are [lab-04.Rmd](lab-04.Rmd) and
[investigation.Rmd](investigation.Rmd). The files
[report.Rmd](report.Rmd) and [presentation.Rmd](presentation.Rmd) are the
**original course templates for later work**, not completed final submissions.

## Reproduce

Open `ids-project.Rproj` in RStudio. Install these packages if needed:

```r
install.packages(c("tidyverse", "knitr", "rmarkdown"))
```

Use Knit on either completed R Markdown file, or run:

```r
source("render_lab04.R")
source("check_lab04.R")
```

The CSV is included, so re-running the analysis does not download data.
[session-info.txt](session-info.txt) records the R and package versions.
[verification.txt](verification.txt) records the final checks.

## Lab 04 requirements

- [x] Confirm the four-person group.
- [x] Clone the course project template.
- [x] Create a local version-controlled RStudio project.
- [x] Create the private project repository and invite the three teammates and uoeIDS.
- [x] Save and inspect a candidate dataset.
- [x] Complete the optional Star Wars exercises.
- [x] Knit both completed worksheets and inspect the figures.
- [ ] Confirm the candidate topic with all members and the course organiser.
- [ ] Verify that each member has accepted the project repository invitation.
- [ ] Check current project dates on Learn.

Repository setup and invitation results are recorded in
[repository-status.md](repository-status.md). An invitation being sent does
not mean that the recipient has accepted it.

## Course context

The supplied Lab 04 worksheet calls for a project kick-off and initial data
exploration. Its eight Star Wars exercises are optional. It does not ask for
the completed end-of-term report or presentation this week.

The project template and linked course website give different weeks for the
first check-in. Use the current Learn announcement or ask the organiser;
no deadline is treated as confirmed in this workspace.

Course references:
[project instructions](https://uoe-ids.netlify.app/assessments/project/) and
[original template](https://github.com/uoeIDS/project_template).

## Analysis notes

- Original data are unchanged. Short column names and dates are prepared in R.
- Non-operating hours are kept in the full data and reported separately.
- The bike plots describe operating hours in one city and one year.
- Star Wars missing numerical values are handled separately for each plot.
- Initial associations are described without claiming causation.
- ChatGPT helped prepare the code and draft descriptions; the code and
  numerical summaries were checked in R. Group review is still needed.
