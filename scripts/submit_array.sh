#!/usr/bin/env bash

source ./PATHS
source ./user_parameters.sh

if [ "$NUM" -eq 1 ]; then
    sbatch --export=ALL -D ${LOC_SLURMS} ./jobarray.sh
else
    sbatch --export=ALL -a 1-$NUM -D ${LOC_SLURMS} ./jobarray.sh
fi
