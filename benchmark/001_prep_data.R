#' Script that prepares data for super learner
library(data.table)
library(lubridate)

## 1. PATIENTS DATA ------------------------------------------------------------
#DT_patient <- fread("/global/scratch/users/skyqiu/multimodal-deep-learning/data/patients.csv.gz")
DT_patient <- fread("data/raw/patients.csv.gz")

# select columns needed
DT_patient <- DT_patient[, .(subject_id, gender, anchor_age)]


## 2. ADMISSIONS DATA ----------------------------------------------------------
#DT_admission <- fread("/global/scratch/users/skyqiu/multimodal-deep-learning/data/admissions.csv.gz")
DT_admission <- fread("data/raw/admissions.csv.gz")

date_time_cols <- c("admittime", "dischtime", "deathtime", "edregtime", "edouttime")
DT_admission[, (date_time_cols) := lapply(.SD, as_datetime), .SDcols = date_time_cols]

# define length of stay
DT_admission[, los := ceiling(as.numeric(difftime(dischtime, admittime, units = "days")))]

# define time-to-readmission
setorder(DT_admission, subject_id, admittime)
DT_admission[, admit_count := 1:.N, by = subject_id]
DT_admission[, index_admittime := shift(admittime, type = "lead"), by = subject_id]
DT_admission[, t_2_readmit := as.numeric(difftime(index_admittime, dischtime, units = "days")), by = subject_id]
DT_admission[, t_2_readmit := ceiling(t_2_readmit)]
DT_admission[, readmit_30d := 0]
DT_admission[t_2_readmit <= 30, readmit_30d := 1]

# select columns needed
DT_admission <- DT_admission[, .(subject_id, hadm_id, admission_type, 
                                 admission_location, discharge_location, 
                                 insurance, language, marital_status,
                                 race, readmit_30d)]

# merge data
DT <- merge(DT_admission, DT_patient, all.x = TRUE, by = "subject_id")
rm(DT_admission)
rm(DT_patient)
gc()


## 3. DIAGNOSES DATA -----------------------------------------------------------
#DT_diagnosis <- fread("/global/scratch/users/skyqiu/multimodal-deep-learning/data/diagnoses_icd.csv.gz")
DT_diagnosis <- fread("data/raw/diagnoses_icd.csv.gz")
DT_diagnosis[, diag_count := 1:.N, by = .(subject_id, hadm_id)]

# define number of diagnoses
DT_diagnosis[, n_diag := .N, by = .(subject_id, hadm_id)]

# select columns and rows needed
DT_diagnosis <- DT_diagnosis[diag_count == 1]
DT_diagnosis <- DT_diagnosis[, .(subject_id, hadm_id, n_diag)]

# merge data
DT <- merge(DT, DT_diagnosis, all.x = TRUE, by = c("subject_id", "hadm_id"))
rm(DT_diagnosis)
gc()


## 4. LABS DATA ----------------------------------------------------------------
#DT_lab <- fread("/global/scratch/users/skyqiu/multimodal-deep-learning/data/labevents.csv.gz")
DT_lab <- fread("data/raw/labevents.csv.gz")
DT_lab <- DT_lab[!is.na(hadm_id)]
DT_lab[, lab_count := 1:.N, by = .(subject_id, hadm_id)]

# define number of labs, number of abnormal labs
DT_lab[, n_lab := .N, by = .(subject_id, hadm_id)]
DT_lab[, abnormal := 0]
DT_lab[flag == "abnormal", abnormal := 1]
DT_lab[, n_abnorm_lab := sum(abnormal), by = .(subject_id, hadm_id)]

# select columns and rows needed
DT_lab <- DT_lab[lab_count == 1]
DT_lab <- DT_lab[, .(subject_id, hadm_id, n_lab, n_abnorm_lab)]

# merge data
DT <- merge(DT, DT_lab, all.x = TRUE, by = c("subject_id", "hadm_id"))
rm(DT_lab)
gc()

# final cleaning
DT <- DT[!is.na(n_diag)]
DT[is.na(n_lab), n_lab := 0]
DT[is.na(n_abnorm_lab), n_abnorm_lab := 0]

save(DT, file = "benchmark/data/tabular.RData")
