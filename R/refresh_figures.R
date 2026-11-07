# Visual review, 6 November 2026. Read frozen outputs; do not refit or resample.
# Sources and decisions: docs/data-to-viz-review.md.
refresh_presentation_figures <- function(r) {
  suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr); library(ggplot2)})
  colours <- c(Female="#B5A2FF",Male="#55DFCA")
  shapes <- c(Female=16,Male=17)
  outcome_colours <- c(Graduate="#7E8A9C",Enrolled="#D9B977",Dropout="#F28C93")
  plot_theme <- theme_minimal(base_size=17,base_family="sans") + theme(
    text=element_text(colour="#F5F6FA"),axis.text=element_text(colour="#ADB7C9",size=13),
    axis.title=element_text(colour="#D0D7E4",size=15),
    panel.grid.major=element_line(colour="#252B37",linewidth=.35),panel.grid.minor=element_blank(),
    panel.background=element_rect(fill="#080A0F",colour=NA),plot.background=element_rect(fill="#080A0F",colour=NA),
    strip.background=element_blank(),strip.text=element_text(colour="#DCE2EF",size=14),
    plot.title.position="plot",plot.title=element_text(face="bold",size=17,colour="#F5F6FA"),
    legend.background=element_rect(fill="#080A0F",colour=NA),legend.key=element_rect(fill="#080A0F",colour=NA),
    legend.text=element_text(size=13),legend.title=element_text(size=13),
    legend.position="bottom",plot.margin=margin(10,14,10,10))
  save_review_plot <- function(name,p,width=10.8,height=5.1) {
    p <- p + plot_theme
    ggsave(file.path("figures",paste0(name,".png")),p,width=width,height=height,dpi=190,bg="#080A0F")
    ggsave(file.path("figures",paste0(name,".pdf")),p,width=width,height=height,device="pdf",bg="#080A0F")
  }

  p_outcomes <- ggplot(r$outcomes,aes(target,n,fill=target)) + geom_col(width=.52) +
    geom_text(aes(label=paste0(num(n),"\n",pct(proportion))),vjust=-.3,size=5,colour="#F5F6FA") +
    scale_fill_manual(values=outcome_colours,guide="none") +
    scale_y_continuous(expand=expansion(mult=c(0,.2))) + labs(x=NULL,y="Students")
  save_review_plot("recorded-outcomes",p_outcomes,width=9,height=5.2)

  # Recover the same training rows from the recorded partition, never from test outcomes.
  raw <- read_delim("data/data.csv",delim=";",show_col_types=FALSE,name_repair="minimal")
  membership <- read_csv("results/split-membership.csv",show_col_types=FALSE)
  training_ids <- membership$row_id[membership$split=="Training"]
  training <- raw[training_ids,] %>% transmute(
    target=factor(Target,levels=c("Graduate","Enrolled","Dropout")),
    age=`Age at enrollment`,admission_grade=`Admission grade`)
  counts <- training %>% count(target,name="n")
  stopifnot(nrow(training)==r$configuration$training_n,
    identical(as.integer(counts$n),c(1324L,476L,852L)))
  axis_labels <- setNames(paste0(counts$target,"\nn = ",num(counts$n)),as.character(counts$target))
  eda <- training %>% pivot_longer(-target,names_to="variable",values_to="value") %>%
    mutate(variable=factor(variable,levels=c("age","admission_grade"),
      labels=c("Age at enrolment (years)","Admission grade (0-200)")))
  p_eda <- ggplot(eda,aes(target,value,fill=target)) +
    geom_boxplot(width=.58,outlier.alpha=.28,colour="#D0D7E4") +
    facet_wrap(~variable,scales="free_y",nrow=1) +
    scale_x_discrete(labels=axis_labels) + scale_fill_manual(values=outcome_colours,guide="none") +
    labs(x=NULL,y=NULL)
  save_review_plot("entry-profiles",p_eda)

  grid <- read_csv("results/validation-thresholds.csv",show_col_types=FALSE)
  threshold_long <- grid %>% select(threshold,Sensitivity,Specificity,WarningRate) %>%
    pivot_longer(-threshold,names_to="measure",values_to="value") %>%
    mutate(measure=factor(measure,levels=c("Sensitivity","Specificity","WarningRate"),
      labels=c("Dropouts identified","Non-dropouts not flagged","All students flagged")))
  p_threshold <- ggplot(threshold_long,aes(threshold,value,colour=measure,linetype=measure)) +
    geom_line(linewidth=1.15) + geom_hline(yintercept=.7,colour="#68768B",linetype="dotted") +
    geom_vline(xintercept=r$threshold,colour="#D9B977",linetype="dashed") +
    scale_colour_manual(values=c("#55DFCA","#B5A2FF","#BAC5D4")) +
    scale_linetype_manual(values=c("solid","dashed","dotdash")) +
    scale_y_continuous(labels=function(x) paste0(100*x,"%"),limits=c(0,1)) +
    labs(x="Warning threshold",y=NULL,colour=NULL,linetype=NULL)
  save_review_plot("validation-threshold",p_threshold,width=10.8,height=5.8)

  metric_labels <- c(WarningRate="Flagged among all students",FPR="Flagged among non-dropouts (FPR)",
    FNR="Missed among recorded dropouts (FNR)",PPV="Dropouts among flagged students (PPV)",
    FOR="Dropouts among unflagged students")
  gm <- r$group_metrics
  denominators <- bind_rows(lapply(names(metric_labels),function(metric) {
    den <- switch(metric,WarningRate=gm$n,FPR=gm$FP+gm$TN,FNR=gm$TP+gm$FN,
      PPV=gm$TP+gm$FP,FOR=gm$FN+gm$TN)
    tibble(gender=as.character(gm$gender),metric=metric,denominator=den)
  }))
  fair <- r$group_intervals %>% filter(metric %in% names(metric_labels)) %>%
    mutate(gender=as.character(gender)) %>% left_join(denominators,by=c("gender","metric")) %>%
    mutate(y=6-match(metric,names(metric_labels))+if_else(gender=="Female",.14,-.14))
  stopifnot(nrow(fair)==10L,!anyNA(fair$denominator),all(fair$denominator>0))
  # Verify every plotted rate against the matching count and denominator.
  for (i in seq_len(nrow(fair))) {
    group <- gm[as.character(gm$gender)==fair$gender[i],]
    numerator <- switch(fair$metric[i],WarningRate=group$TP+group$FP,FPR=group$FP,
      FNR=group$FN,PPV=group$TP,FOR=group$FN)
    stopifnot(abs(fair$estimate[i]-numerator/fair$denominator[i])<1e-12)
  }
  p_fair <- ggplot(fair,aes(x=estimate,y=y,colour=gender,shape=gender)) +
    geom_errorbar(aes(xmin=lower,xmax=upper),orientation="y",width=.10,linewidth=.65) +
    geom_point(size=3) +
    geom_text(aes(x=.97,label=paste0("n = ",num(denominator))),hjust=1,size=4,show.legend=FALSE) +
    scale_colour_manual(values=colours) + scale_shape_manual(values=shapes) +
    scale_x_continuous(labels=function(x) paste0(round(100*x),"%"),limits=c(0,1),breaks=seq(0,1,.2)) +
    scale_y_continuous(breaks=5:1,labels=unname(metric_labels),limits=c(.55,5.45)) +
    labs(x="Observed rate (n at right is the denominator for each point)",y=NULL,
      colour="Recorded gender",shape="Recorded gender")
  save_review_plot("group-fairness",p_fair,width=12,height=5.3)

  gap_data <- r$gaps %>% filter(metric %in% names(metric_labels)) %>%
    mutate(metric=factor(metric,levels=rev(names(metric_labels)),labels=rev(unname(metric_labels))))
  p_gaps <- ggplot(gap_data,aes(100*estimate,metric)) +
    geom_vline(xintercept=0,colour="#8291A6",linetype="dashed") +
    geom_errorbar(aes(xmin=100*lower,xmax=100*upper),orientation="y",width=.17,colour="#B5A2FF") +
    geom_point(colour="#B5A2FF",size=3) + labs(x="Male minus Female (percentage points)",y=NULL)
  save_review_plot("fairness-gaps",p_gaps,width=11.5,height=5.2)
  boots <- read_csv("results/bootstrap-gaps.csv",show_col_types=FALSE)
  fn_ci <- filter(r$gaps,metric=="FNR")
  p_boot <- ggplot(boots,aes(100*FNR)) + geom_histogram(bins=35,fill="#B5A2FF",colour="#080A0F") +
    geom_vline(xintercept=100*c(fn_ci$lower,fn_ci$upper),colour="#D9B977",linewidth=.9) +
    geom_vline(xintercept=0,colour="#CED8E7",linetype="dashed") +
    labs(x="Male minus Female missed-dropout rate (percentage points)",y="Bootstrap samples")
  save_review_plot("bootstrap-fnr-gap",p_boot)

  p_cal <- ggplot(filter(r$calibration,n>=30),aes(mean_score,observed,colour=gender,shape=gender)) +
    geom_abline(slope=1,intercept=0,colour="#8291A6",linetype="dashed") +
    geom_point(aes(size=n),alpha=.9) + scale_colour_manual(values=colours) + scale_shape_manual(values=shapes) +
    guides(size=guide_legend(override.aes=list(colour="#D0D7E4",shape=16))) +
    scale_x_continuous(limits=c(0,1),labels=function(x) paste0(100*x,"%")) +
    scale_y_continuous(limits=c(0,1),labels=function(x) paste0(100*x,"%")) +
    labs(x="Mean predicted probability in a common score band",y="Recorded dropout proportion",
      colour="Recorded gender",shape="Recorded gender",size="Students")
  save_review_plot("probability-calibration",p_cal)

  composition <- read_csv("results/training-course-composition.csv",show_col_types=FALSE)
  ordered_courses <- composition %>% filter(course_group!="Other courses") %>%
    group_by(course_group) %>% summarise(total=sum(n),.groups="drop") %>% arrange(desc(total),course_group) %>% pull(course_group)
  display_order <- c(ordered_courses,"Other courses")
  totals <- composition %>% group_by(gender) %>% summarise(n=sum(n),.groups="drop")
  group_labels <- setNames(paste0(totals$gender," (n = ",num(totals$n),")"),totals$gender)
  composition <- composition %>% mutate(course_group=factor(course_group,levels=rev(display_order)))
  p_composition <- ggplot(composition,aes(proportion,course_group,fill=gender)) +
    geom_col(position=position_dodge(width=.75),width=.65) +
    scale_fill_manual(values=colours,labels=group_labels) +
    scale_x_continuous(labels=function(x) paste0(round(100*x),"%"),limits=c(0,NA),expand=expansion(mult=c(0,.08))) +
    labs(x="Share of each recorded-gender group in training data",y=NULL,fill="Recorded gender")
  save_review_plot("course-composition",p_composition)

  jsonlite::write_json(list(review_date="2026-11-06",no_refitting=TRUE,no_resampling=TRUE,
    training_counts=counts,metric_denominators=denominators,course_display_order=display_order,
    inputs=c("data/data.csv","results/split-membership.csv","results/analysis.rds",
      "results/validation-thresholds.csv","results/training-course-composition.csv")),
    "results/visual-review-checks.json",pretty=TRUE,auto_unbox=TRUE)
  invisible(TRUE)
}
