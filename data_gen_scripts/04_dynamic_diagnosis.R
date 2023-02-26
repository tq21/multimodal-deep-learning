#' Script that processes static diagnosis data from raw data files

## LOAD DATA -------------------------------------------------------------------
static_diagnosis <- fread("data/raw/diagnoses_icd.csv.gz")

## SET COLUMN TYPES ------------------------------------------------------------

## CLEAN DATA ------------------------------------------------------------------
static_diagnosis[, -icd_version]

print("04: DYNAMIC LAB DATA PROCESSED!")
