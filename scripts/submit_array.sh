#!/usr/bin/env bash

source ./PATHS
source ./user_parameters.sh

sbatch --export=ALL -a 1-$NUM -D ${LOC_SLURMS} ./jobarray.sh
