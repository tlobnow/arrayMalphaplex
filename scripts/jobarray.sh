#!/usr/bin/env bash
#SBATCH --job-name=ARRAY
#SBATCH --time=1:00:00
#SBATCH --mem=1000
#SBATCH --mail-type=NONE
#SBATCH --mail-user=lobnow@mpiib-berlin.mpg.de
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=72
#SBATCH -o job_%A_%a.log 	#direct both standard output and standard error to the same file
#SBATCH --open-mode=append

source /u/${USER}/arrayMalphaplex/scripts/PATHS
source ${LOC_SCRIPTS}/FUNCTIONS

# Retrieve OUT_NAME and STOICHIOMETRY from the INFO_LIST:
if [ -z "$SLURM_ARRAY_TASK_ID" ]; then
  # Handle the single job case here. Manually set OUT_NAME and STOICHIOMETRY based on the second line in the table. (ignore header)
  OUT_NAME=$(awk 'NR==2 {print $1}' "$INFO_LIST")
  STOICHIOMETRY=$(awk 'NR==2 {print $2}' "$INFO_LIST")
else
  # Handle the array job case here.
  OUT_NAME=$(awk -v line_num=${SLURM_ARRAY_TASK_ID} 'NR==line_num+1 {print $1}' "$INFO_LIST")
  STOICHIOMETRY=$(awk -v line_num=${SLURM_ARRAY_TASK_ID} 'NR==line_num+1 {print $2}' "$INFO_LIST")
  echo "Array-ID:" ${SLURM_ARRAY_TASK_ID}
fi

printf "DATE:\t\t%s\n" "$(date +%Y-%m-%d_%H:%M:%S)"
printf "MODE:\t\t%s\n" "$MODE"
printf "OUT_NAME:\t%s\n" "$OUT_NAME"
printf "STOICHIOMETRY:\t%s\n" "$STOICHIOMETRY"
printf "LOC_FEATURES:\t%s\n" "$LOC_FEATURES"
printf "OUT_DIR:\t%s\n" "$OUT_DIR"
LOC_OUT=${PTMP}/output_files/$OUT_NAME
printf "LOC_OUT:\t%s\n" "$LOC_OUT"
printf "LOC_FEA_GEN:\t%s\n" "$LOC_FEA_GEN"
printf "LOC_LISTS:\t%s\n" "$LOC_LISTS"
printf "LOC_SLURMS:\t%s\n" "$LOC_SLURMS"
printf "LOC_FLAGS:\t%s\n" "$LOC_FLAGS"
printf "INFO_LIST:\t%s\n" "$INFO_LIST"

module purge
module load jdk/8.265 gcc/10 impi/2021.2 fftw-mpi R/4.0.2

# Check if MSA needs to be run (starts job if necessary)
stoichiometry="${1:-$STOICHIOMETRY}"
CONTINUE="TRUE"
FASTA_EXISTS="TRUE"

# Check if the stoichiometry is provided
if [ -z "$STOICHIOMETRY" ]; then
        echo "Error: STOICHIOMETRY is required" >&2
fi

echo "---------------- MSA & Features ----------------"
# Split the stoichiometry into individual feature-count pairs and check if all monomers are prepped
IFS='/' read -ra stoichiometry_pairs <<< "$STOICHIOMETRY"
for pair in "${stoichiometry_pairs[@]}"; do
        check_and_process_fasta "${stoichiometry_pairs[@]}"
done

# 1. You initialize the output directory and set the initial files using initialize_run_dir.
# 2. You assess the current status of model files in the output directory using assess_model_files.
# 3. You check for the existence of any models. If none are found (OUT_RLX_MODEL_COUNT, MODEL_COUNT,
#	OUT_MODEL_COUNT, MOVED_OUT_MODEL_COUNT are all zero),
#	you proceed to submit new jobs based on the mode (submit_jobs_based_on_mode).
# 4. If some models are found, you evaluate each model's prediction status using evaluate_prediction_for_model for models 1 to 5.
# 5. If all five models are successfully predicted (PREDICTION_TICKER is 5 or greater), you proceed to process the prediction using process_prediction.

# The code covers the following scenarios:
	# If models are missing and mode allows for submission, new jobs will be submitted.
	# If some or all models exist, their status will be evaluated.
	# If all models have passed, the prediction is processed.

    echo "                 *** Passed *** "
if [ "$CONTINUE" = "TRUE" ]; then
    echo "---------------- Initialization ----------------"
    initialize_run_dir "$LOC_SCRIPTS" "$OUT_NAME"
    echo "                 *** Passed *** "

    echo "------------------ Job Submit ------------------"
    cd ${LOC_SCRIPTS}/runs/${OUT_NAME}
    declare -A MODEL_COUNTS # Initialize an associative array to hold the counts for each individual model
    submit_jobs_based_on_mode "$MODE" "$LOC_FASTA" "$LOC_FEATURES" "$STOICHIOMETRY" "$LOC_OUT" "$OUT_NAME" "$LOC_SCRIPTS" "$FILE"
    echo "submit_jobs_based_on_mode finished."
    echo "                 *** Passed *** "

    echo "------------- Checking Model Status ------------"
    echo "ALL_MODELS_PRESENT:" $ALL_MODELS_PRESENT

    if [ "$ALL_MODELS_PRESENT" = "true" ]; then
	echo "                 *** Passed *** "
        echo "------------ Starting File Processing ----------"
        process_prediction "$LOC_OUT" "$LOC_SCRIPTS" "$OUT_NAME" "$OUT_DIR" "$STORAGE"
        sleep 3  # Wait for 3 seconds
	echo "                *** Passed *** "
        echo "------------- Moving SLURM Files ---------------"
        matching_files=($(grep -l "$OUT_NAME" ${LOC_SLURMS}/*))
        for file in "${matching_files[@]}"; do
            mv "$file" "$LOC_OUT/"
        done
        NEW_NAME_DATE=$(add_date "$LOC_OUT")
        echo "NEW_NAME_DATE: $NEW_NAME_DATE"
        mv "${OUT_DIR}/${NEW_NAME_DATE}" "$STORAGE"
        NEW_NAME_DATE_REP=$(add_rep "${STORAGE}/${NEW_NAME_DATE}")
        echo "NEW_NAME_DATE_REP: $NEW_NAME_DATE_REP"
    else
        echo "WAITING FOR ${OUT_NAME} MODELING TO FINISH."
    fi
else
    echo "WAITING FOR ${OUT_NAME} MSA TO FINISH."
fi
echo "                   *** Passed *** "
echo "----------------------- Done! -------------------"
