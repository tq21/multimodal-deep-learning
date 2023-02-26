#' Script that generates input data for deep learning model\
#' 
#' INPUT: /data/raw/patients.csv.gz
#'        /data/raw/admissions.csv.gz
#'        /data/raw/labevents.csv.gz
#'        /data/raw/diagnoses_icd.csv.gz
#'  
#' OUTPUT: /data/processed/01_static_patient.csv
#'         /data/processed/02_static_admission.csv
#'         /data/processed/03_dynamic_lab.csv
#'         /data/processed/04_dynamic_diagnosis.csv
library(data.table)
library(lubridate)
library(mltools)

## PROCESS ALL DATA ------------------------------------------------------------
source("data_gen_scripts/01_static_patient.R")
source("data_gen_scripts/02_static_admission.R")
source("data_gen_scripts/03_dynamic_lab.R")
source("data_gen_scripts/04_dynamic_diagnosis.R")






## Load data -------------------------------------------------------------------
DT_patients <- fread("sample_data/patients_sample.csv")
DT_patients <- DT_patients[, .(subject_id, gender, anchor_age)]

DT_admissions <- fread("sample_data/admissions_sample.csv")
DT_admissions <- DT_admissions[, -c("dischtime", "deathtime", 
                                    "edregtime", "edouttime", "hospital_expire_flag", 
                                    "ADMIT_COUNT", "READMIT", "T_TO_READMIT"), with = FALSE]

DT_labs <- fread("sample_data/labs_sample.csv")
DT_labs <- DT_labs[, -c("labevent_id", "specimen_id", "value", "ref_range_lower", 
                        "ref_range_upper", "priority", "comments"), with = FALSE]

# TODO: covert non numeric data to numeric

## Labels ----------------------------------------------------------------------
DT_labels <- DT_admissions[, .(subject_id, hadm_id, READMIT_ONE_WEEK)]
write.csv(DT_labels, file = "data/labels.csv", row.names = FALSE)

## Patient data ----------------------------------------------------------------
DT_patients <- DT_patients[, .(subject_id, gender)]
DT_patients[, gender := as.integer(gender == "M")]

write.csv(DT_patients, file = "data/patients.csv", row.names = FALSE)

## Admissions data -------------------------------------------------------------
DT_admissions[, admittime := ymd_hms(admittime)]
DT_admissions[discharge_location == "", discharge_location := NA]
DT_admissions[language == "?", language := NA]
DT_admissions[marital_status == "", marital_status := NA]

factor_cols <- c("admission_type", "admission_location", "discharge_location", 
                 "insurance", "language", "marital_status", "race")
DT_admissions[, (factor_cols) := lapply(.SD, as.factor), .SDcols = factor_cols]
DT_admissions <- one_hot(DT_admissions)

write.csv(DT_admissions[, -c("admittime", "READMIT_ONE_WEEK"), with = FALSE],
          file = "data/admissions.csv")

## Labs data -------------------------------------------------------------------
DT_labs[, charttime := ymd_hms(charttime)]
DT_labs[flag == "", flag := "normal"]
DT_labs <- merge(DT_labs, DT_admissions[, .(subject_id, hadm_id, admittime)], all.x = TRUE)
DT_labs[, T_EVENT := as.numeric(difftime(charttime, admittime, units = "mins"))]
DT_labs <- DT_labs[, -c("admittime", "charttime", "storetime", "valueuom"), with = FALSE]

DT_labs[, flag := as.integer(flag == "abnormal")]

write.csv(DT_labs[!is.na(T_EVENT)], file = "data/lab_events.csv", row.names = FALSE)

# TODO: think about how to deal with anchor age

## Construct time stamp --------------------------------------------------------

# Question: no event time for diagnosis? ignore diagnosis table for now.

# todo: add time stamp for lab events
