library(sl3)
library(SuperLearner)
library(origami)
library(future)
library(dplyr)
options(sl3.verbose = TRUE)

cpus <- 30
plan(multisession, workers = cpus, gc = TRUE)

load("/global/scratch/users/skyqiu/multimodal-deep-learning/data/tabular.RData")

# super learner library
suggested_learners <- list(
  mean = make_learner(Lrnr_mean),
  glm = make_learner(Lrnr_glm_fast),
  xgb = make_learner(Lrnr_xgboost, nrounds = 20, maxdepth = 6),
  ranger_small = make_learner(Lrnr_ranger, num.trees = 500),
  lasso_fast = make_learner(Lrnr_glmnet, nfold = 3),
  ridge_fast = make_learner(Lrnr_glmnet, nfold = 3, alpha = 0),
  enet_fast = make_learner(Lrnr_glmnet, nfold = 3, alpha = 0.5),
  earth = make_learner(Lrnr_earth),
  bayesglm = make_learner(Lrnr_bayesglm),
  gam = Lrnr_pkg_SuperLearner$new(SL_wrapper = "SL.gam"),
  bart = Lrnr_dbarts$new(ndpost = 1000, verbose = FALSE),
  xgb_SL = make_learner(Lrnr_xgboost, nrounds = 1000, max_depth = 4, eta = 0.1)
)
sl <- make_learner(Lrnr_sl, suggested_learners)

# create sl3 task
covars <- names(DT)[!names(DT) %in% c("subject_id", "hadm_id", "train_test", "readmit_30d")]
outcome <- "readmit_30d"
task <- make_sl3_Task(DT, covars, outcome)
DT <- task$data

# train test split: 10% testing
set.seed(123)
n_test <- round(0.1 * nrow(DT))
train_test <- c(rep(1, nrow(DT) - n_test), rep(0, n_test))
train_test <- sample(train_test, nrow(DT))
DT[, train_test := train_test]

# train and test task
covars <- names(DT)[!names(DT) %in% c("subject_id", "hadm_id", "train_test", "readmit_30d")]
training_task <- make_sl3_Task(DT[train_test == 1], covars, outcome)
testing_task <- make_sl3_Task(DT[train_test == 0], covars, outcome)

# fit the super learner
start_time <- proc.time()
sl_fit <- sl$train(task)
end_time <- proc.time()

time_elapsed <- end_time - start_time

save(list = c("sl_fit", "training_task", "testing_task", "time_elapsed"), 
     file = "/global/scratch/users/skyqiu/multimodal-deep-learning/out/sl_fit_tabular.RData")
