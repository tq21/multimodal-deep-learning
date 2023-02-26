#' Script that processes static admission data from raw data files

## LOAD DATA -------------------------------------------------------------------
static_admission <- fread("data/raw/admissions.csv.gz")

## SET COLUMN TYPES ------------------------------------------------------------
date_time_cols <- c("admittime", "dischtime", "deathtime", "edregtime", "edouttime")
static_admission[, (date_time_cols) := lapply(.SD, as_datetime), .SDcols = date_time_cols]

## CLEAN DATA ------------------------------------------------------------------
# define time-to-readmission
static_admission[, admit_count := 1:.N, by = subject_id]
static_admission[, t_2_readmit := as.numeric(difftime(admittime, shift(dischtime, type = "lag"), units = "days")), by = subject_id]
static_admission[, t_2_readmit := ceiling(t_2_readmit)]
static_admission[, readmit_1_week := 0]
static_admission[t_2_readmit <= 7, readmit_1_week := 1]

print("02: STATIC ADMISSION DATA PROCESSED!")
