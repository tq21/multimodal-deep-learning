#' Script that processes dynamic lab data from raw data files

## LOAD DATA -------------------------------------------------------------------
dynamic_lab <- fread("data/raw/labevents.csv.gz")

## SET COLUMN TYPES ------------------------------------------------------------
dynamic_lab[, charttime := as_datetime(charttime)]

## CLEAN DATA ------------------------------------------------------------------
dynamic_lab[flag == "", flag := "normal"]

# define time of lab since admission (in minutes)
DT_admit_time <- static_admission[, .(subject_id, hadm_id, admittime)]
dynamic_lab <- merge(dynamic_lab, DT_admit_time, all.x = TRUE)
dynamic_lab[, lab_time_since_admit := as.numeric(difftime(charttime, admittime, units = "mins"))]
dynamic_lab <- DT_labs[, .(subject_id, hadm_id, itemid, valuenum, flag)]

print("03: DYNAMIC LAB DATA PROCESSED!")
