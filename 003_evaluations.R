library(pROC)
library(caret)

get_pred_summary <- function(y_test, preds) {
  res_roc <- roc(as.vector(y_test), as.vector(preds))
  best_threshold = coords(res_roc, "best", input="threshold", best.method="youden")$threshold
  best_preds_class = factor(ifelse(as.vector(preds) > best_threshold, 1, 0))
  cm = confusionMatrix(data=best_preds_class, reference=as.factor(y_test))
  return(list('cm' = cm,
              'res_roc' = res_roc))
}
# create test task, evaluate AUC
test_task <- make_sl3_Task(testing, covars, outcome)
train_pred <- sl_fit$predict()
test_pred <- sl_fit$predict(test_task)
get_pred_summary(task$data$readmit_30d, train_pred) # AUC
get_pred_summary(test_task$data$readmit_30d, test_pred) # AUC