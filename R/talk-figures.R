# The talk uses the published split and scores. These drawings never select
# a model or a threshold. Both charts of group misses use the same scale.
talk_figures <- function(r) {
  suppressPackageStartupMessages(library(ggplot2))
  paper <- "#F5F2EC"
  ink <- "#172D30"
  muted <- "#445B59"
  teal <- "#086764"
  purple <- "#694D87"
  gold <- "#986922"
  line <- "#CACCC2"
  group_colours <- c(Female = purple, Male = teal)
  outcome_colours <- c(Graduate = "#9CBDB4", Enrolled = "#D8C39B", Dropout = "#A48EAE")
  percent <- scales::label_percent(accuracy = 1)
  slide_theme <- theme_minimal(base_size = 20, base_family = "sans") +
    theme(text = element_text(colour = ink), axis.title = element_text(size = 17),
          axis.text = element_text(colour = muted, size = 15),
          panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = line, linewidth = 0.3),
          plot.background = element_rect(fill = paper, colour = NA),
          plot.margin = margin(8, 15, 5, 10), legend.position = "bottom",
          legend.text = element_text(size = 15), legend.title = element_blank(),
          strip.text = element_text(colour = ink, size = 17, face = "bold"))

  save_chart <- function(name, chart, width, height) {
    stem <- file.path("figures", paste0("talk-", name))
    ggsave(paste0(stem, ".png"), chart, width = width, height = height,
           dpi = 155, bg = paper)
    ggsave(paste0(stem, ".pdf"), chart, width = width, height = height,
           device = grDevices::pdf, useDingbats = FALSE, bg = paper)
  }
  dir.create("figures", showWarnings = FALSE)

  # One dot per record, with a single ink colour because no groups are encoded.
  id <- seq_len(r$audit$rows) - 1L
  cohort <- data.frame(column = id %% 56L, row = id %/% 56L)
  dots <- ggplot(cohort, aes(column, row)) + geom_point(size = 0.66, colour = teal) +
    scale_x_continuous(expand = c(0, 0.6)) + scale_y_continuous(expand = c(0, 0.6)) +
    coord_fixed() + theme_void() + theme(plot.margin = margin(0, 0, 0, 0))
  save_chart("cohort", dots, 4.2, 5.9)

  outcomes <- r$outcomes
  outcomes$target <- factor(outcomes$target, levels = c("Dropout", "Enrolled", "Graduate"))
  bars <- ggplot(outcomes, aes(n, target, fill = target)) +
    geom_col(width = 0.53) +
    geom_text(aes(label = num(n)), nudge_x = 45, hjust = 0, size = 6.5, colour = ink) +
    scale_fill_manual(values = outcome_colours, guide = "none") +
    scale_x_continuous(limits = c(0, max(outcomes$n) * 1.20), expand = c(0, 0),
                       breaks = c(0, 1000, 2000), labels = scales::label_comma()) +
    labs(x = "Student records", y = NULL) + slide_theme +
    theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 18))
  save_chart("outcomes", bars, 8.9, 3.75)

  # Only the rows assigned to training contribute to these boxplots.
  raw <- read.csv("data/data.csv", sep = ";", check.names = FALSE, fileEncoding = "UTF-8-BOM")
  split <- read.csv("results/split-membership.csv")
  rows <- raw[split$row_id[split$split == "Training"], ]
  order <- c("Graduate", "Enrolled", "Dropout")
  training <- data.frame(outcome = factor(rows$Target, levels = order),
                         age = rows[["Age at enrollment"]], grade = rows[["Admission grade"]])
  long <- tidyr::pivot_longer(training, c(age, grade), names_to = "measure", values_to = "value")
  long$measure <- factor(long$measure, levels = c("age", "grade"),
                         labels = c("Age at enrolment (years)", "Admission grade (out of 200)"))
  count <- table(training$outcome)
  labels <- setNames(paste0(names(count), "\nn = ", num(as.numeric(count))), names(count))
  profiles <- ggplot(long, aes(outcome, value, fill = outcome)) +
    geom_boxplot(width = 0.57, linewidth = 0.7, outlier.size = 1, outlier.alpha = 0.38,
                 colour = ink) +
    facet_wrap(~measure, scales = "free_y", nrow = 1) + scale_x_discrete(labels = labels) +
    scale_fill_manual(values = outcome_colours, guide = "none") +
    labs(x = NULL, y = NULL) + slide_theme + theme(panel.grid.major.x = element_blank(),
                                                 panel.spacing = grid::unit(0.55, "in"))
  save_chart("profiles", profiles, 11.2, 3.85)

  validation <- read.csv("results/validation-thresholds.csv")
  rates <- tidyr::pivot_longer(validation, c(Sensitivity, Specificity), names_to = "measure",
                               values_to = "rate")
  curves <- ggplot(rates, aes(threshold, rate, colour = measure, linetype = measure)) +
    geom_hline(yintercept = r$configuration$validation_sensitivity_target,
               colour = "#9F8658", linetype = "dotted") +
    geom_vline(xintercept = r$threshold, colour = gold, linewidth = 0.65) +
    geom_line(linewidth = 1.1) +
    annotate("point", x = r$threshold, y = r$threshold_row$Sensitivity,
             shape = 21, size = 3.6, colour = teal, fill = paper, stroke = 1.4) +
    scale_colour_manual(values = c(Sensitivity = teal, Specificity = purple)) +
    scale_linetype_manual(values = c(Sensitivity = "solid", Specificity = "longdash")) +
    scale_x_continuous(breaks = c(0.1, r$threshold, 0.5, 0.7)) +
    scale_y_continuous(limits = c(0, 1), breaks = c(0, 0.5, 0.7, 1), labels = percent) +
    labs(x = "Candidate warning threshold", y = NULL) + slide_theme +
    theme(legend.key.width = grid::unit(0.45, "in"), legend.box.margin = margin(-7, 0, 0, 0))
  save_chart("validation", curves, 8.1, 3.9)

  main <- r$metrics[r$metrics$Rule == "Enrolment model: validation rule", ]
  totals <- c(main$TP + main$FN, main$TP + main$FP)
  den <- data.frame(y = c(2, 1), rate = main$TP / totals,
                    context = c("Recorded dropouts", "Warnings issued"),
                    matched = paste(num(main$TP), "/", num(totals)),
                    other = c(paste(num(main$FN), "missed"), paste(num(main$FP), "false warnings")))
  denominators <- ggplot(den) +
    geom_rect(aes(xmin = 0, xmax = 1, ymin = y - 0.18, ymax = y + 0.18), fill = "#DADBD1") +
    geom_rect(aes(xmin = 0, xmax = rate, ymin = y - 0.18, ymax = y + 0.18), fill = teal) +
    geom_text(aes(x = rate / 2, y = y, label = matched), colour = "white", size = 6.1,
              fontface = "bold") +
    geom_text(aes(x = (rate + 1) / 2, y = y, label = other), colour = ink, size = 5.8) +
    geom_text(aes(x = 0, y = y + 0.34, label = context), hjust = 0, size = 6.6, colour = ink) +
    geom_text(aes(x = 1, y = y + 0.34, label = pct(rate)), hjust = 1, size = 6.7,
              colour = teal, fontface = "bold") +
    scale_x_continuous(limits = c(0, 1), expand = expansion(add = 0.01)) +
    scale_y_continuous(limits = c(0.75, 2.48), expand = c(0, 0)) + theme_void()
  save_chart("denominators", denominators, 10.9, 2.85)

  # Both panels share the same axis, positions and styling. The second panel
  # simply reveals the alternate threshold row. Labels are calculated from
  # integer confusion counts, so displayed percentages never drive differences.
  primary <- r$group_metrics
  alternate <- read.csv("results/fairness-threshold-05.csv")
  primary$row <- 2
  alternate$row <- 1
  cols <- c("gender", "TP", "FN", "row")
  groups <- rbind(as.data.frame(primary[, cols]), alternate[, cols])
  groups$total <- groups$FN + groups$TP
  groups$rate <- groups$FN / groups$total
  stopifnot(all(primary$TP + primary$FN == alternate$TP + alternate$FN),
            all(primary$gender == alternate$gender))
  miss_plot <- function(include_alternate) {
    d <- if (include_alternate) groups else groups[groups$row == 2, ]
    caption <- paste0(d$gender, "  ", pct(d$rate), "\n", num(d$FN), " / ", num(d$total))
    # Place female labels above and male labels below the rate, keeping the
    # numerator and denominator with their marker even when points get close.
    label_y <- d$row + ifelse(d$gender == "Female", 0.24, -0.25)
    row_ticks <- if (include_alternate) c(1, 2) else 2
    row_labels <- if (include_alternate) c("0.50", num(r$threshold, 2)) else num(r$threshold, 2)
    ggplot(d, aes(rate, row)) +
      geom_segment(aes(x = 0, xend = 1, y = row, yend = row), data = unique(d["row"]),
                   inherit.aes = FALSE, colour = "#B6BFB7", linewidth = 0.55) +
      geom_point(aes(colour = gender, shape = gender), size = 4.7) +
      geom_text(aes(colour = gender), y = label_y, label = caption, lineheight = 0.96,
                size = 5.1, fontface = "bold", show.legend = FALSE) +
      scale_colour_manual(values = group_colours, guide = "none") +
      scale_shape_manual(values = c(Female = 16, Male = 17), guide = "none") +
      scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25), labels = percent,
                         expand = expansion(add = 0.015)) +
      scale_y_continuous(limits = c(0.48, 2.53), breaks = row_ticks, labels = row_labels,
                         expand = c(0, 0)) +
      labs(x = "Share of recorded dropouts missed", y = "Cutoff") + slide_theme +
      theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 18, face = "bold"),
            axis.title.y = element_text(size = 15))
  }
  save_chart("misses", miss_plot(FALSE), 11.0, 3.45)
  save_chart("thresholds", miss_plot(TRUE), 11.0, 3.45)
  invisible(NULL)
}
