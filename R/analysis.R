# All statistical calculations and data figures for this project are produced here.
source("R/setup.R")
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(readr); library(ggplot2)})
for (folder in c("results","figures")) dir.create(folder,showWarnings=FALSE)
seed <- 20261105L
set.seed(seed)

# 1. Preserve the original labels and a stable file-row identifier.
raw <- read_delim("data/data.csv",delim=";",locale=locale(decimal_mark="."),
                  trim_ws=TRUE,show_col_types=FALSE,name_repair="minimal")
stopifnot(nrow(raw)==4424L,ncol(raw)==37L,!anyNA(raw))
stopifnot(setequal(unique(raw$Target),c("Dropout","Graduate","Enrolled")))
stopifnot(all(raw$Gender %in% c(0,1)),all(raw$`Admission grade`>=0 & raw$`Admission grade`<=200))
stopifnot(all(raw$`Daytime/evening attendance` %in% c(0,1)))
profile <- apply(as.data.frame(raw),1,paste,collapse="\034")
profile_id <- match(profile,unique(profile))
students <- raw %>% transmute(
  row_id=row_number(), profile_id=profile_id,
  target=factor(Target,levels=c("Graduate","Enrolled","Dropout")),
  dropout=as.integer(Target=="Dropout"),
  gender=factor(if_else(Gender==0,"Female","Male"),levels=c("Female","Male")),
  age=`Age at enrollment`, admission_grade=`Admission grade`,
  previous_grade=`Previous qualification (grade)`,
  age10=age/10, admission10=admission_grade/10,
  course=factor(as.character(Course)),
  attendance=factor(if_else(`Daytime/evening attendance`==1,"Daytime","Evening"),
                    levels=c("Daytime","Evening")))

outcomes <- students %>% count(target,name="n") %>% mutate(proportion=n/sum(n))
write_csv(outcomes,"results/outcome-counts.csv")

# 2. Document every original field, including omitted and time-uncertain inputs.
field_audit <- tibble(field=names(raw)) %>% mutate(
  timing=case_when(
    grepl("Curricular units",field) ~ "End of first or second semester",
    field %in% c("Debtor","Tuition fees up to date","Scholarship holder") ~ "Exact baseline measurement time not established",
    field %in% c("Unemployment rate","Inflation rate","GDP") ~ "Annual macroeconomic measure; individual cohort/year absent",
    field=="Target" ~ "Normal course endpoint, usually 3 years; Nursing 4 years",
    TRUE ~ "Enrolment/background information according to the source; no individual timestamps"),
  role=case_when(
    field %in% c("Age at enrollment","Admission grade","Course") ~ "Primary predictor",
    field=="Daytime/evening attendance" ~ "Excluded: deterministic within course in training data",
    field=="Gender" ~ "Group audit; secondary model only",
    field=="Target" ~ "Outcome; never a predictor",
    grepl("Curricular units",field) ~ "Excluded: unavailable at enrolment",
    field %in% c("Debtor","Tuition fees up to date","Scholarship holder") ~ "Excluded: timing uncertainty",
    field %in% c("Unemployment rate","Inflation rate","GDP") ~ "Excluded: scope and cohort-proxy concern",
    TRUE ~ "Not selected: small, interpretable primary model"),
  statistical_type=case_when(
    field %in% c("Age at enrollment","Admission grade","Previous qualification (grade)",
                 "Unemployment rate","Inflation rate","GDP") ~ "Numerical",
    grepl("Curricular units",field) ~ "Numerical semester measure",
    field=="Application order" ~ "Ordinal category",
    TRUE ~ "Categorical, including numeric codes"))
write_csv(field_audit,"results/variable-timing-audit.csv")
unknown_codes <- tibble(field=c("Mother's qualification","Father's qualification", "Mother's occupation","Father's occupation"),
  source_note=c("Code 34 means Unknown","Code 34 means Unknown","Codes 90/99 need codebook interpretation","Codes 90/99 need codebook interpretation"),
  count_34_or_90_or_99=vapply(c("Mother's qualification","Father's qualification","Mother's occupation","Father's occupation"),
    function(x) sum(raw[[x]] %in% c(34,90,99)),integer(1)))
write_csv(unknown_codes,"results/coded-unknown-audit.csv")

# 3. Approximately 60/20/20 within original outcome and recorded-gender strata.
# Exact full-record repeats, if present, stay together; they are not assumed to be one person.
units <- students %>% distinct(profile_id,target,gender)
units$split <- NA_character_
strata <- split(seq_len(nrow(units)),interaction(units$target,units$gender,drop=TRUE))
for (ids in strata) {
  ids <- sample(ids)
  n <- length(ids); n_train <- floor(.6*n); n_validation <- floor(.2*n)
  units$split[ids] <- c(rep("Training",n_train),rep("Validation",n_validation),rep("Test",n-n_train-n_validation))
}
students <- students %>% left_join(units %>% select(profile_id,split),by="profile_id",relationship="many-to-one")
stopifnot(!anyNA(students$split),all((students %>% count(profile_id,split) %>% count(profile_id))$n==1))
training <- filter(students,split=="Training")
validation <- filter(students,split=="Validation")
test <- filter(students,split=="Test")
stopifnot(all(table(training$course)>0))
split_counts <- students %>% count(split,gender,target,name="n")
write_csv(split_counts,"results/split-counts.csv")
write_csv(students %>% select(row_id,profile_id,target,gender,split),"results/split-membership.csv")
training_summary <- training %>% group_by(target) %>% summarise(
  n=n(), mean_age=mean(age),median_age=median(age),sd_age=sd(age),
  median_admission=median(admission_grade),iqr_admission=IQR(admission_grade),.groups="drop")
write_csv(training_summary,"results/training-summary.csv")
training_group_rates <- training %>% group_by(gender) %>% summarise(n=n(),dropouts=sum(dropout),rate=mean(dropout),.groups="drop")
write_csv(training_group_rates,"results/training-gender-rates.csv")
training_course_rates <- training %>% group_by(course,gender) %>% summarise(n=n(),dropouts=sum(dropout),rate=mean(dropout),.groups="drop")
write_csv(training_course_rates,"results/training-course-gender-rates.csv")
course_attendance <- table(training$course,training$attendance)
stopifnot(all(rowSums(course_attendance>0)==1))
write_csv(as_tibble(as.data.frame(course_attendance)),"results/training-course-attendance.csv")

# 4. Fixed, interpretable candidate models; no feature search against test outcomes.
primary_formula <- dropout ~ age10 + admission10 + course
primary <- glm(primary_formula,data=training,family=binomial())
with_gender <- glm(update(primary_formula,. ~ . + gender),data=training,family=binomial())
stopifnot(primary$converged,with_gender$converged,all(is.finite(coef(primary))),all(is.finite(coef(with_gender))))
validation$probability <- predict(primary,newdata=validation,type="response")
divide <- function(a,b) ifelse(b>0,a/b,NA_real_)
confusion <- function(y,flag) c(TP=sum(y==1 & flag),FP=sum(y==0 & flag),FN=sum(y==1 & !flag),TN=sum(y==0 & !flag))
rates <- function(z) {
  tp <- unname(z["TP"]); fp <- unname(z["FP"]); fn <- unname(z["FN"]); tn <- unname(z["TN"])
  c(BaseRate=divide(tp+fn,sum(z)),WarningRate=divide(tp+fp,sum(z)),
    FPR=divide(fp,fp+tn),FNR=divide(fn,tp+fn),Sensitivity=divide(tp,tp+fn),Specificity=divide(tn,tn+fp),
    PPV=divide(tp,tp+fp),NPV=divide(tn,tn+fn),FOR=divide(fn,tn+fn),Accuracy=divide(tp+tn,sum(z)),
    BalancedAccuracy=mean(c(divide(tp,tp+fn),divide(tn,tn+fp))))
}
auc_rank <- function(y,p) {
  n1 <- sum(y==1); n0 <- sum(y==0)
  if(!n1 || !n0) return(NA_real_)
  (sum(rank(p,ties.method="average")[y==1])-n1*(n1+1)/2)/(n1*n0)
}
model_metrics <- function(y,p,flag,label) {
  z <- confusion(y,flag); rr <- rates(z)
  tibble(Rule=label,n=length(y),TP=z["TP"],FP=z["FP"],FN=z["FN"],TN=z["TN"],
    AUC=auc_rank(y,p),Brier=mean((p-y)^2),LogLoss=-mean(y*log(pmax(p,1e-12))+(1-y)*log(pmax(1-p,1e-12))),
    !!!as.list(rr))
}
threshold_grid <- bind_rows(lapply(seq(.05,.80,.01),function(t) {
  rr <- rates(confusion(validation$dropout,validation$probability>=t))
  tibble(threshold=t,!!!as.list(rr))
}))
eligible <- threshold_grid %>% filter(Sensitivity>=.70) %>% arrange(desc(Specificity),desc(threshold))
threshold <- if(nrow(eligible)) eligible$threshold[1] else min(threshold_grid$threshold)
threshold_target_attained <- nrow(eligible)>0
write_csv(threshold_grid,"results/validation-thresholds.csv")
configuration <- list(seed=seed,training_n=nrow(training),validation_n=nrow(validation),test_n=nrow(test),
  primary_formula=deparse(primary_formula),threshold=threshold,validation_sensitivity_target=.70,
  target_attained=threshold_target_attained,test_used_for_selection=FALSE,refit_after_validation=FALSE)
# The frozen settings are written before any test predictions are calculated.
jsonlite::write_json(configuration,"results/frozen-configuration.json",pretty=TRUE,auto_unbox=TRUE)
write_csv(tibble(term=names(coef(primary)),coefficient=unname(coef(primary))),"results/primary-coefficients.csv")
saveRDS(list(primary=primary,with_gender=with_gender),"results/fitted-models.rds")

# 5. Hold-out evaluation; the model and threshold are now fixed.
test$probability <- predict(primary,newdata=test,type="response")
test$probability_gender <- predict(with_gender,newdata=test,type="response")
test$flag <- test$probability>=threshold
test$flag_05 <- test$probability>=.5
test$flag_gender <- test$probability_gender>=threshold
test$baseline_probability <- mean(training$dropout)
metrics <- bind_rows(
  model_metrics(test$dropout,test$baseline_probability,rep(FALSE,nrow(test)),"Always no warning"),
  model_metrics(test$dropout,test$probability,test$flag_05,"Enrolment model: threshold 0.50"),
  model_metrics(test$dropout,test$probability,test$flag,"Enrolment model: validation rule"),
  model_metrics(test$dropout,test$probability_gender,test$flag_gender,"Add recorded gender: same threshold"))
write_csv(metrics,"results/test-metrics.csv")
write_csv(test %>% select(row_id,target,dropout,gender,course,probability,probability_gender,flag,flag_05,flag_gender),
          "results/test-predictions.csv")

group_summary <- function(d,flag_col="flag") bind_rows(lapply(levels(d$gender),function(g) {
  x <- filter(d,gender==g); z <- confusion(x$dropout,x[[flag_col]])
  tibble(gender=g,n=nrow(x),TP=z["TP"],FP=z["FP"],FN=z["FN"],TN=z["TN"],!!!as.list(rates(z)))
}))
group_metrics <- group_summary(test)
group_metrics_05 <- group_summary(test,"flag_05")
group_metrics_gender <- group_summary(test,"flag_gender")
write_csv(group_metrics,"results/fairness-group-metrics.csv")
write_csv(group_metrics_05,"results/fairness-threshold-05.csv")
write_csv(group_metrics_gender,"results/fairness-gender-inclusive.csv")

# 6. Percentile bootstrap of fixed held-out predictions, within recorded-gender groups.
B <- 5000L
set.seed(seed+1L)
metric_names <- names(rates(c(TP=1,FP=1,FN=1,TN=1)))
boot <- array(NA_real_,dim=c(B,length(metric_names),2),dimnames=list(NULL,metric_names,levels(test$gender)))
overall_boot <- matrix(NA_real_,nrow=B,ncol=4,dimnames=list(NULL,c("AUC","Brier","Sensitivity","Accuracy")))
group_rows <- lapply(levels(test$gender),function(g) which(test$gender==g))
for(b in seq_len(B)) {
  draws <- lapply(group_rows,function(ids) sample(ids,length(ids),replace=TRUE))
  for(g in seq_len(2)) {
    ids <- draws[[g]]
    boot[b,,g] <- rates(confusion(test$dropout[ids],test$flag[ids]))
  }
  ids <- unlist(draws,use.names=FALSE)
  rr <- rates(confusion(test$dropout[ids],test$flag[ids]))
  overall_boot[b,] <- c(auc_rank(test$dropout[ids],test$probability[ids]),
    mean((test$probability[ids]-test$dropout[ids])^2),rr["Sensitivity"],rr["Accuracy"])
}
q95 <- function(x) quantile(x,c(.025,.975),na.rm=TRUE,names=FALSE)
group_intervals <- bind_rows(lapply(seq_len(2),function(g) bind_rows(lapply(metric_names,function(m) {
  ci <- q95(boot[,m,g])
  tibble(gender=levels(test$gender)[g],metric=m,estimate=group_metrics[[m]][g],lower=ci[1],upper=ci[2])
}))))
gap_boot <- boot[,,"Male"]-boot[,,"Female"]
gaps <- bind_rows(lapply(metric_names,function(m) {
  ci <- q95(gap_boot[,m])
  tibble(metric=m,estimate=group_metrics[[m]][2]-group_metrics[[m]][1],lower=ci[1],upper=ci[2],
    definition="Male minus Female; fixed model and validation threshold")
}))
overall_intervals <- bind_rows(lapply(colnames(overall_boot),function(m) {
  ci <- q95(overall_boot[,m]); tibble(metric=m,estimate=metrics[[m]][3],lower=ci[1],upper=ci[2])
}))
write_csv(group_intervals,"results/fairness-group-intervals.csv")
write_csv(gaps,"results/fairness-gaps.csv")
write_csv(overall_intervals,"results/test-metric-intervals.csv")
write_csv(as_tibble(gap_boot),"results/bootstrap-gaps.csv")

# 7. Pre-specified sensitivity to the outcome definition; keep the original partitions.
train_resolved <- training %>% filter(target!="Enrolled")
test_resolved <- test %>% filter(target!="Enrolled")
resolved_model <- glm(primary_formula,data=train_resolved,family=binomial())
stopifnot(resolved_model$converged)
resolved_probability <- predict(resolved_model,newdata=test_resolved,type="response")
sensitivity <- bind_rows(
  model_metrics(test_resolved$dropout,test_resolved$probability,test_resolved$probability>=threshold,
                "Primary fit evaluated on Dropout/Graduate only"),
  model_metrics(test_resolved$dropout,resolved_probability,resolved_probability>=threshold,
                "Refit on Dropout/Graduate training rows; same threshold"))
write_csv(sensitivity,"results/enrolled-definition-sensitivity.csv")

# 8. A descriptive probability check using common bands, separate from label sufficiency.
calibration <- test %>% mutate(band=cut(probability,breaks=seq(0,1,.2),include.lowest=TRUE)) %>%
  group_by(gender,band) %>% summarise(n=n(),mean_score=mean(probability),observed=mean(dropout),.groups="drop")
write_csv(calibration,"results/calibration-bins.csv")

# 9. Figures. Statistical visualisations are generated directly in R.
colours <- c(Female="#6658A6",Male="#007E78")
outcome_colours <- c(Graduate="#667585",Enrolled="#B99540",Dropout="#B64F4B")
theme_set(theme_minimal(base_size=17,base_family="sans") + theme(
  panel.grid.minor=element_blank(),plot.title.position="plot",plot.title=element_text(face="bold"),
  legend.position="bottom",plot.margin=margin(10,14,10,10)))
save_plot <- function(name,p,width=10.8,height=5.1) {
  ggsave(file.path("figures",paste0(name,".png")),p,width=width,height=height,dpi=190,bg="white")
  ggsave(file.path("figures",paste0(name,".pdf")),p,width=width,height=height,device="pdf")
}
p_outcomes <- ggplot(outcomes,aes(x=target,y=n,fill=target)) + geom_col(width=.65) +
  geom_text(aes(label=paste0(num(n),"\n",pct(proportion))),vjust=-.3,size=5) +
  scale_fill_manual(values=outcome_colours,guide="none") + scale_y_continuous(expand=expansion(mult=c(0,.18))) +
  labs(x=NULL,y="Students",title="Three recorded outcomes at the normal course endpoint")
save_plot("recorded-outcomes",p_outcomes)

eda <- training %>% select(target,age,admission_grade) %>% pivot_longer(-target,names_to="variable",values_to="value") %>%
  mutate(variable=factor(variable,levels=c("age","admission_grade"),labels=c("Age at enrolment (years)","Admission grade (0-200)")))
p_eda <- ggplot(eda,aes(x=target,y=value,fill=target)) + geom_boxplot(width=.58,outlier.alpha=.23) +
  facet_wrap(~variable,scales="free_y",nrow=1) + scale_fill_manual(values=outcome_colours,guide="none") +
  labs(x=NULL,y=NULL,title="Entry profiles overlap across the three outcomes") + theme(axis.text.x=element_text(size=12))
save_plot("entry-profiles",p_eda)

threshold_long <- threshold_grid %>% select(threshold,Sensitivity,Specificity,WarningRate) %>%
  pivot_longer(-threshold,names_to="measure",values_to="value") %>%
  mutate(measure=factor(measure,levels=c("Sensitivity","Specificity","WarningRate"),
    labels=c("Dropouts identified","Non-dropouts not flagged","All students flagged")))
p_threshold <- ggplot(threshold_long,aes(threshold,value,colour=measure,linetype=measure)) +
  geom_line(linewidth=1.15) + geom_hline(yintercept=.7,colour="#B1B7BF",linetype="dotted") +
  geom_vline(xintercept=threshold,colour="#273449",linetype="dashed") +
  scale_colour_manual(values=c("#007E78","#6658A6","#6B737D")) +
  scale_linetype_manual(values=c("solid","solid","longdash")) +
  scale_y_continuous(labels=function(x) paste0(100*x,"%"),limits=c(0,1)) +
  labs(x="Warning threshold",y=NULL,colour=NULL,linetype=NULL,
    title=paste0("Validation choice: a common threshold of ",num(threshold,2)))
save_plot("validation-threshold",p_threshold)

metric_labels <- c(WarningRate="Flagged among all students",FPR="Flagged among non-dropouts (FPR)",
  FNR="Missed among recorded dropouts (FNR)",PPV="Dropouts among flagged students (PPV)",FOR="Dropouts among unflagged students")
fair_plot_data <- group_intervals %>% filter(metric %in% names(metric_labels)) %>%
  mutate(metric=factor(metric,levels=rev(names(metric_labels)),labels=rev(unname(metric_labels))))
p_fair <- ggplot(fair_plot_data,aes(x=estimate,y=metric,colour=gender)) +
  geom_errorbar(aes(xmin=lower,xmax=upper),orientation="y",width=.18,position=position_dodge(width=.45),linewidth=.65) +
  geom_point(position=position_dodge(width=.45),size=3) + scale_colour_manual(values=colours) +
  scale_x_continuous(labels=function(x) paste0(round(100*x),"%"),limits=c(0,1),breaks=seq(0,1,.2)) +
  labs(x="Rate within the stated group and denominator",y=NULL,colour="Recorded gender") +
  theme(axis.text.y=element_text(size=12),legend.text=element_text(size=13))
save_plot("group-fairness",p_fair,width=11.5,height=5.2)

gap_plot_data <- gaps %>% filter(metric %in% names(metric_labels)) %>%
  mutate(metric=factor(metric,levels=rev(names(metric_labels)),labels=rev(unname(metric_labels))))
p_gaps <- ggplot(gap_plot_data,aes(x=100*estimate,y=metric)) + geom_vline(xintercept=0,colour="#A8ABB3",linetype="dashed") +
  geom_errorbar(aes(xmin=100*lower,xmax=100*upper),orientation="y",width=.17,colour="#6658A6") +
  geom_point(colour="#6658A6",size=3) + labs(x="Male minus Female (percentage points)",y=NULL,
    title="Pointwise bootstrap intervals for the observed gaps") + theme(axis.text.y=element_text(size=12))
save_plot("fairness-gaps",p_gaps,width=11.5,height=5.2)

fn_ci <- filter(gaps,metric=="FNR")
p_boot <- ggplot(tibble(gap=100*gap_boot[,"FNR"]),aes(gap)) + geom_histogram(bins=35,fill="#6658A6",colour="white") +
  geom_vline(xintercept=100*c(fn_ci$lower,fn_ci$upper),colour="#B99540",linewidth=.9) +
  geom_vline(xintercept=0,colour="#273449",linetype="dashed") +
  labs(x="Male minus Female missed-dropout rate (percentage points)",y="Bootstrap samples",
    title="Uncertainty in the missed-dropout gap")
save_plot("bootstrap-fnr-gap",p_boot)

p_cal <- ggplot(filter(calibration,n>=30),aes(mean_score,observed,colour=gender)) +
  geom_abline(slope=1,intercept=0,colour="#9AA0AA",linetype="dashed") +
  geom_point(aes(size=n),alpha=.9) + scale_colour_manual(values=colours) +
  scale_x_continuous(limits=c(0,1),labels=function(x) paste0(100*x,"%")) +
  scale_y_continuous(limits=c(0,1),labels=function(x) paste0(100*x,"%")) +
  labs(x="Mean predicted probability in a common score band",y="Recorded dropout proportion",colour="Recorded gender",size="Students")
save_plot("probability-calibration",p_cal)

# A training-only composition check; it does not identify the cause of a fairness gap.
course_labels <- c("33"="Biofuel technologies","171"="Animation / multimedia","8014"="Social service (evening)",
  "9003"="Agronomy","9070"="Communication design","9085"="Veterinary nursing","9119"="Computer engineering",
  "9130"="Equinculture","9147"="Management","9238"="Social service","9254"="Tourism","9500"="Nursing",
  "9556"="Oral hygiene","9670"="Advertising / marketing","9773"="Journalism / communication",
  "9853"="Basic education","9991"="Management (evening)")
top_courses <- training %>% count(course,sort=TRUE) %>% slice_head(n=6) %>% pull(course) %>% as.character()
composition <- training %>% mutate(course_group=if_else(as.character(course) %in% top_courses,
    unname(course_labels[as.character(course)]),"Other courses")) %>% count(gender,course_group,name="n") %>%
  group_by(gender) %>% mutate(proportion=n/sum(n)) %>% ungroup()
write_csv(composition,"results/training-course-composition.csv")
p_composition <- ggplot(composition,aes(x=proportion,y=course_group,fill=gender)) +
  geom_col(position=position_dodge(width=.75),width=.65) + scale_fill_manual(values=colours) +
  scale_x_continuous(labels=function(x) paste0(round(100*x),"%"),expand=expansion(mult=c(0,.08))) +
  labs(x="Share of each recorded-gender group in training data",y=NULL,fill="Recorded gender",
    title="Course composition differs between the groups")
save_plot("course-composition",p_composition)

# 10. Save the common result object and provenance used by every document.
audit <- list(rows=nrow(raw),columns=ncol(raw),predictors=ncol(raw)-1L,missing_cells=sum(is.na(raw)),
  exact_duplicate_rows=sum(duplicated(raw)),courses=nlevels(students$course),
  international=sum(raw$International==1),age_range=range(students$age),
  source_paper_predictor_count=35L,downloaded_predictor_count=36L)
r <- list(seed=seed,bootstrap_reps=B,audit=audit,outcomes=outcomes,split_counts=split_counts,
  configuration=configuration,training_summary=training_summary,training_group_rates=training_group_rates,
  threshold=threshold,threshold_row=threshold_grid[abs(threshold_grid$threshold-threshold)<1e-8,],
  metrics=metrics,group_metrics=group_metrics,group_intervals=group_intervals,gaps=gaps,
  overall_intervals=overall_intervals,sensitivity=sensitivity,calibration=calibration,
  gender_comparison=group_metrics_gender,field_audit=field_audit,
  data_sha256=file_sha256("data/data.csv"),
  analysis_sha256=file_sha256("R/analysis.R"),
  plan_sha256=file_sha256("docs/analysis-plan.md"))
saveRDS(r,"results/analysis.rds")
jsonlite::write_json(r,"results/analysis-summary.json",pretty=TRUE,auto_unbox=TRUE,na="null",digits=10)
writeLines(capture.output(sessionInfo()),"results/session-info.txt")
cat("Analysis complete. Training/validation/test:",nrow(training),nrow(validation),nrow(test),"\n")
cat("Threshold:",threshold,"\n")
print(metrics %>% select(Rule,n,TP,FP,FN,TN,AUC,Brier,Sensitivity,PPV,WarningRate))
print(group_metrics %>% select(gender,n,TP,FP,FN,TN,BaseRate,WarningRate,FPR,FNR,PPV,FOR))
print(gaps %>% filter(metric %in% c("WarningRate","FPR","FNR","PPV","FOR")))
