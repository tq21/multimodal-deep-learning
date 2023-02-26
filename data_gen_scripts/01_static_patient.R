#' Script that processes static patient data from raw data files
library(data.table)
library(lubridate)

## LOAD DATA -------------------------------------------------------------------
static_patient <- fread("data/raw/patients.csv.gz")

## SET COLUMN TYPES ------------------------------------------------------------
static_patient[, dod := as_date(dod)]

## CLEAN DATA ------------------------------------------------------------------
# gender
static_patient[, gender := as.factor(gender)]
static_patient[, gender := as.numeric(gender) - 1] # 0:F; M:1

# select columns needed
static_patient <- static_patient[, .(subject_id, gender, anchor_age)]

print("01: STATIC PATIENT DATA PROCESSED!")
