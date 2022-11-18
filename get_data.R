library(data.table)
library(lubridate)

# Demographic data
DT_patients <- setDT(read.csv(gzfile("MIMIC-IV/patients.csv.gz")))
DT_patients[, .(subject_id, gender, anchor_age, dod)]

# Admission data
DT_admissions <- setDT(read.csv(gzfile("MIMIC-IV/admissions.csv.gz")))
DT_admissions[, admittime := ymd_hms(admittime)]
DT_admissions[, dischtime := ymd_hms(dischtime)]
setorder(DT_admissions, subject_id, admittime)

# Diagnosis data
DT_diagnosis <- setDT(read.csv(gzfile("MIMIC-IV/diagnoses_icd.csv.gz")))
DT_diagnosis_code <- setDT(read.csv(gzfile("MIMIC-IV/d_icd_diagnoses.csv.gz")))

# Labs data
DT_labs <- fread("MIMIC-IV/labevents.csv.gz")
DT_labs_code <- setDT(read.csv(gzfile("MIMIC-IV/d_labitems.csv.gz")))

# Define time-to-readmission
DT_admissions[, ADMIT_COUNT := 1:.N, by = subject_id]
DT_admissions[, READMIT := as.integer(ADMIT_COUNT > 1)]
DT_admissions[, T_TO_READMIT := as.numeric(difftime(admittime, shift(dischtime, type = "lag"), units = "days")), by = subject_id]
DT_admissions[, T_TO_READMIT := ceiling(T_TO_READMIT)]
DT_admissions[, READMIT_ONE_WEEK := 0]
DT_admissions[T_TO_READMIT <= 7, READMIT_ONE_WEEK := 1]

DT_admissions[READMIT_ONE_WEEK == 1, .N]

write.csv(DT_admissions, file = "MIMIC-IV/admissions_with_label.csv", row.names = FALSE)
