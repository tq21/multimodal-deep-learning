library(data.table)
library(dplyr)

DT_patients <- fread("MIMIC-IV/patients.csv.gz")
DT_admissions <- fread("MIMIC-IV/admissions_with_label.csv")
DT_diagnosis <- fread("MIMIC-IV/diagnoses_icd.csv.gz")
DT_labs <- fread("MIMIC-IV/labevents.csv.gz")

set.seed(123)
patients_id_sample <- sample(unique(DT_admissions$subject_id), 5000)
patients_sample <- DT_patients[subject_id %in% patients_id_sample, ]
admissions_sample <- DT_admissions[subject_id %in% patients_id_sample, ]
diagnosis_sample <- DT_diagnosis[subject_id %in% patients_id_sample, ]
labs_sample <- DT_labs[subject_id %in% patients_id_sample, ]

write.csv(patients_sample, file = "sample_data/patients_sample.csv", row.names = FALSE)
write.csv(admissions_sample, file = "sample_data/admissions_sample.csv", row.names = FALSE)
write.csv(diagnosis_sample, file = "sample_data/diagnosis_sample.csv", row.names = FALSE)
write.csv(labs_sample, file = "sample_data/labs_sample.csv", row.names = FALSE)
