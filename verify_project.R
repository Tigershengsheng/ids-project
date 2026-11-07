# Independent checks against raw rows and saved predictions, not a second analysis fit.
source("R/setup.R")
checks <- character()
check <- function(condition,label) {
  if(!isTRUE(condition)) stop("Verification failed: ",label)
  checks <<- c(checks,label)
}
near <- function(a,b,tol=1e-10) isTRUE(all.equal(as.numeric(a),as.numeric(b),tolerance=tol))
raw <- read.csv("data/data.csv",sep=";",check.names=FALSE,fileEncoding="UTF-8-BOM")
names(raw) <- trimws(names(raw))
membership <- read.csv("results/split-membership.csv")
p <- read.csv("results/test-predictions.csv")
metrics <- read.csv("results/test-metrics.csv",check.names=FALSE)
groups <- read.csv("results/fairness-group-metrics.csv")
gaps <- read.csv("results/fairness-gaps.csv")
bootstrap <- read.csv("results/bootstrap-gaps.csv")
r <- readRDS("results/analysis.rds")
models <- readRDS("results/fitted-models.rds")
check(file_sha256("data/data.csv")=="3ef126de5cefff26eb11fbb4237f1a1401cb64b488e2f1d598c23cedeb4c45ae","Raw file matches independently retrieved SHA-256")
check(nrow(raw)==4424 && ncol(raw)==37 && !anyNA(raw),"Raw dimensions and explicit missingness")
check(identical(sort(membership$row_id),seq_len(nrow(raw))) && !anyDuplicated(membership$row_id),"Every original student row retained exactly once in split membership")
check(length(intersect(membership$row_id[membership$split=="Training"],p$row_id))==0,"Training and test rows disjoint")
check(length(intersect(membership$row_id[membership$split=="Validation"],p$row_id))==0,"Validation and test rows disjoint")
check(setequal(p$row_id,membership$row_id[membership$split=="Test"]),"Predictions cover only and all test rows")
check(all(tapply(membership$split,membership$profile_id,function(x) length(unique(x)))==1),"Exact full-record profiles stay within one partition")
check(identical(as.character(raw$Target[p$row_id]),p$target),"Saved test labels match raw source row IDs")
y <- as.integer(raw$Target[p$row_id]=="Dropout")
gender <- ifelse(raw$Gender[p$row_id]==0,"Female","Male")
check(all(p$dropout==y) && all(p$gender==gender),"Binary endpoint and recorded-gender mapping")
check(sum(raw$Target=="Enrolled")==794 && sum(p$target=="Enrolled")==160,"Enrolled remains visible in the primary cohort and test sample")
term_names <- attr(terms(models$primary),"term.labels")
check(identical(term_names,c("age10","admission10","course")),"Primary formula contains only the three documented entry inputs")
check(!any(grepl("gender|semester|sem|debt|fee|scholar|attendance",names(coef(models$primary)),ignore.case=TRUE)),"No primary sensitive, post-enrolment, timing-uncertain or redundant input")
new_data <- function(ids) data.frame(age10=raw$`Age at enrollment`[ids]/10,
  admission10=raw$`Admission grade`[ids]/10,
  course=factor(as.character(raw$Course[ids]),levels=models$primary$xlevels$course))
X <- model.matrix(delete.response(terms(models$primary)),new_data(p$row_id),contrasts.arg=models$primary$contrasts)
manual_probability <- plogis(drop(X %*% coef(models$primary)))
check(max(abs(manual_probability-p$probability))<1e-12,"Saved probabilities match direct design-matrix/coefficient calculation")
check(all(p$flag==(p$probability>=r$threshold)) && all(p$flag_05==(p$probability>=.5)),"Saved warnings use the two stated thresholds")

# Recalculate threshold choice from validation rows and the saved training fit.
ids <- membership$row_id[membership$split=="Validation"]
vX <- model.matrix(delete.response(terms(models$primary)),new_data(ids),contrasts.arg=models$primary$contrasts)
vp <- plogis(drop(vX %*% coef(models$primary))); vy <- as.integer(raw$Target[ids]=="Dropout")
grid <- seq(.05,.80,.01)
sens <- sapply(grid,function(t) sum(vp>=t & vy==1)/sum(vy==1))
spec <- sapply(grid,function(t) sum(vp<t & vy==0)/sum(vy==0))
eligible <- which(sens>=.7)
best <- eligible[order(-spec[eligible],-grid[eligible])][1]
check(near(r$threshold,grid[best]),"Threshold maximises validation specificity subject to the pre-specified sensitivity target")
check(nrow(r$threshold_row)==1 && near(r$threshold_row$threshold,r$threshold),"Cached chosen-threshold row is unique")
check(!r$configuration$test_used_for_selection && !r$configuration$refit_after_validation,"Configuration records no test selection or validation refit")

# Independent confusion counts and alternative AUC calculation.
z <- c(TP=sum(y==1 & p$flag),FP=sum(y==0 & p$flag),FN=sum(y==1 & !p$flag),TN=sum(y==0 & !p$flag))
check(near(z,unlist(metrics[3,c("TP","FP","FN","TN")])) && sum(z)==nrow(p),"Primary confusion counts sum to the held-out sample")
pairwise_auc <- mean(outer(p$probability[y==1],p$probability[y==0],">") + .5*outer(p$probability[y==1],p$probability[y==0],"=="))
check(near(pairwise_auc,metrics$AUC[3]),"AUC agrees with independent positive-negative pair comparisons")
check(near(mean((p$probability-y)^2),metrics$Brier[3]),"Brier score agrees with direct probability error")
check(near(z["TP"]/(z["TP"]+z["FN"]),metrics$Sensitivity[3]) && near(z["TP"]/(z["TP"]+z["FP"]),metrics$PPV[3]),"Sensitivity and PPV have distinct correct denominators")

for(g in c("Female","Male")) {
  q <- which(gender==g); row <- groups[groups$gender==g,]
  tp <- sum(y[q]==1 & p$flag[q]); fp <- sum(y[q]==0 & p$flag[q]); fn <- sum(y[q]==1 & !p$flag[q]); tn <- sum(y[q]==0 & !p$flag[q])
  check(near(c(tp,fp,fn,tn),unlist(row[c("TP","FP","FN","TN")])),paste(g,"confusion counts independently match raw-row evaluation"))
  expected <- c((tp+fp)/length(q),fp/(fp+tn),fn/(tp+fn),tp/(tp+fp),fn/(fn+tn))
  check(near(expected,unlist(row[c("WarningRate","FPR","FNR","PPV","FOR")])),paste(g,"all three fairness criteria use the stated conditioning groups"))
  check(near(row$FOR,1-row$NPV),paste(g,"sufficiency includes the unflagged prediction stratum"))
}
check(nrow(bootstrap)==5000 && all(is.finite(as.matrix(bootstrap))),"Bootstrap contains 5,000 estimable gap replicates")
for(metric in c("WarningRate","FPR","FNR","PPV","FOR")) {
  row <- gaps[gaps$metric==metric,]
  estimate <- groups[groups$gender=="Male",metric]-groups[groups$gender=="Female",metric]
  interval <- quantile(bootstrap[[metric]],c(.025,.975),names=FALSE)
  check(near(estimate,row$estimate) && near(interval,c(row$lower,row$upper)),paste(metric,"gap direction and percentile interval agree with exports"))
}
check(identical(r$data_sha256,file_sha256("data/data.csv")) && identical(r$analysis_sha256,file_sha256("R/analysis.R")) &&
      identical(r$plan_sha256,file_sha256("docs/analysis-plan.md")),"Cached analysis fingerprints match current data, R source and plan")
html <- paste(readLines("presentation.html",encoding="UTF-8",warn=FALSE),collapse="\n")
check(grepl("187",html,fixed=TRUE) && grepl("44.4%",html,fixed=TRUE) && grepl("0.31",html,fixed=TRUE),"Rendered slide content includes the verified primary results")
check(grepl("warning=FALSE",paste(readLines("presentation.Rmd",warn=FALSE),collapse="\n"),fixed=TRUE) &&
      grepl("echo=FALSE",paste(readLines("presentation.Rmd",warn=FALSE),collapse="\n"),fixed=TRUE),"Presentation code and routine messages are hidden in the compiled deck")
writeLines(c(paste(length(checks),"independent checks passed"),checks),"results/verification.txt")
jsonlite::write_json(list(checks_passed=length(checks),checks=checks),"results/verification.json",pretty=TRUE,auto_unbox=TRUE)
cat(length(checks),"independent checks passed.\n")
