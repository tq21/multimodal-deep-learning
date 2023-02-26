#!/bin/bash
# Job name:
#SBATCH --job-name=multi_dl_sl_tabular
#
# Partition:
#SBATCH --partition=savio3
#
#SBATCH --qos=biostat_savio3_normal
#SBATCH --account=co_biostat
#
# Wall clock limit ('0' for unlimited):
#SBATCH --time=72:00:00
#
# Number of nodes for use case:
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --exclusive
#
# Mail type:
#SBATCH --mail-type=all
#
# Mail user:
#SBATCH --mail-user=sky.qiu@berkeley.edu

mkdir -p logs;
module load r;
R CMD BATCH --no-save 002_super_learner.R logs/002_super_learner.Rout
