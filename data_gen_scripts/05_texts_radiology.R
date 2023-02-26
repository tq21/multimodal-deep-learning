#' Script that processes radiology texts data from raw data files

## LOAD DATA -------------------------------------------------------------------
texts_radiology <- fread("data/raw/radiology.csv.gz")

## SET COLUMN TYPES ------------------------------------------------------------

## CLEAN DATA ------------------------------------------------------------------
static_diagnosis[, -icd_version]

print("04: DYNAMIC LAB DATA PROCESSED!")
