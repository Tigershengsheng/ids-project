# Spoken English for both the main deck and the four-person rehearsal script.
# Source R/setup.R before calling this function from the project root.
talk_notes <- function() {
  source("R/training-course-cv.R", local = TRUE)
  cv <- training_course_cv()$average
  read_result <- function(file) read.csv(file.path("results", file))
  metrics <- read_result("test-metrics.csv")
  baseline <- subset(metrics, Rule == "Always no warning")
  comparison <- subset(metrics, Rule == "Enrolment model: threshold 0.50")
  selected <- subset(metrics, Rule == "Enrolment model: validation rule")
  rate <- read_result("fairness-group-metrics.csv")
  alt <- read_result("fairness-threshold-05.csv")
  female <- subset(rate, gender == "Female")
  male <- subset(rate, gender == "Male")
  women50 <- subset(alt, gender == "Female")
  men50 <- subset(alt, gender == "Male")
  # The stored gap runs male minus female. Reverse the sign and the interval ends together.
  gap <- subset(read_result("fairness-gaps.csv"), metric == "FNR")
  c(
    "Imagine it's enrolment week. A university has advisers who can offer students a check-in, but nobody has any marks for the new semester yet. Could the information on an enrolment form help those advisers decide whom to contact first? Each dot here stands for one student record from a Portuguese institution. Our question has two parts. How well could we flag later recorded dropout, and who would that warning miss?",

    "We looked at 4,424 records at the normal end of the programme, usually three years after entry, or four for Nursing. The institution recorded 1,421 dropouts. That includes some students who changed course or institution. Another 794 were still enrolled. We kept them, alongside graduates, as students with no recorded dropout at that point. They may have graduated later. So what could we actually have known about any of these students on enrolment day?",

    "Start with age in the training records. The line inside each box marks the median. It was 22 for the dropout group and 19 for graduates. Admission grades overlap too. Pick a single age or grade and you can easily find students with different outcomes. Quiz 7 led us to Data to Viz. Boxes hide how many people they represent, so we added the group sizes underneath.",

    paste0(
      "We combined age, admission grade and course in a logistic regression. It gives each student an estimated probability of recorded dropout. Each course is a category because the numbers are just course codes. We fitted the model on training records, chose the cutoff on validation records, and evaluated it on test records. Later, we checked the value of course within training alone. Across five folds, adding course raised average AUC from ",
      num(cv["without_course","AUC"],3),
      " to ",
      num(cv["with_course","AUC"],3),
      ". A score still leaves a practical question. When should it trigger a warning?"
    ),

    "We wanted our rule to find at least seven in ten dropout records in validation. Among the cutoffs that met that target, we chose the one with the fewest false warnings. The cutoff was 0.31. A student with a score at or above that value received a warning. We caught 200 of 284 validation dropouts. We then kept the rule fixed and tried it on the test records.",

    paste0(
      "On the test set, ",
      num(selected$TP),
      " students received a warning and later had a dropout recorded. Take those students as a share of all ",
      num(selected$TP + selected$FN),
      " dropout records and we found ",
      pct(selected$Sensitivity),
      ". That's sensitivity. Now count them among all ",
      num(selected$TP + selected$FP),
      " warnings. Only ",
      pct(selected$PPV),
      " matched a dropout record. That's precision. A rule that never warned anyone would still be right about ",
      pct(baseline$Accuracy,0),
      " of the time here. It would miss every single dropout."
    ),

    paste0(
      "What did the lower cutoff buy us? Compared with 0.50, we found ",
      num(selected$TP-comparison$TP),
      " more dropout records. We also issued ",
      num(selected$FP-comparison$FP),
      " more false warnings. Those extra invitations would take real staff time. We still missed ",
      num(selected$FN),
      " students with a recorded dropout. Were those misses distributed evenly?"
    ),

    paste0(
      "Start with the denominators. These ",
      num(female$TP+female$FN),
      " women and ",
      num(male$TP+male$FN),
      " men all had a dropout recorded. The same rule missed ",
      num(female$FN),
      " women, or ",
      pct(female$FNR),
      ", and ",
      num(male$FN),
      " men, or ",
      pct(male$FNR),
      ". The gap was ",
      pp(-gap$estimate),
      ". We resampled the test records within each group, keeping the model and cutoff fixed. The 95% bootstrap interval for that gap ran from ",
      num(-100*gap$upper,1),
      " to ",
      num(-100*gap$lower,1),
      " points. What happens to the gap if we raise the cutoff?"
    ),

    paste0(
      "At 0.50, the gap shrinks to ",
      pp(women50$FNR-men50$FNR),
      ". Look where both markers went. The rule now misses ",
      pct(women50$FNR),
      " of the women and ",
      pct(men50$FNR),
      " of the men with a dropout record. Total misses rise from ",
      num(selected$FN),
      " to ",
      num(comparison$FN),
      ". If I looked only at the gap, I'd miss the main point. In both groups, someone who later had a dropout recorded was less likely to get a warning."
    ),

    "Before using a rule like this, I'd ask two questions. Does it hold up in the next intake, and can advisers follow up that many warnings? An adviser could use a warning to offer a conversation and check what the student needs. We measured a university record. Finding out whether that conversation actually helps students stay would take a study of the support itself. Thank you.",
    ""  # Slide 11 stays on screen for questions.
  )
}

