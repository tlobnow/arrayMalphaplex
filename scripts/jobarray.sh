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
printf "NAME:\t\t%s\n" "$OUT_NAME"
printf "STOICHIOMETRY:\t%s\n" "$STOICHIOMETRY"
printf "LOC_FEATURES:\t%s\n" "$LOC_FEATURES"
printf "OUT_DIR:\t%s\n" "$OUT_DIR"
LOC_OUT=${PTMP}/output_files/$OUT_NAME
printf "LOC_OUT:\t%s\n" "$LOC_OUT"
printf "OUT_NAME:\t%s\n" "$OUT_NAME"
printf "STOICHIOMETRY:\t%s\n" "$STOICHIOMETRY"
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
echo "check_and_process_fasta finished."

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

if [ "$CONTINUE" = "TRUE" ]; then
	# Initialize the output directory with the template and set the initial files.
        initialize_run_dir "$LOC_SCRIPTS" "$OUT_NAME"
	echo "initialize_run_dir finished."
        # Assess the current status of model files in the output directory.
        assess_model_files "$LOC_OUT" "$OUT_NAME"
	echo "assess_model_files finished."
	echo OUT_RLX_MODEL_COUNT=$OUT_RLX_MODEL_COUNT
        echo OUT_MODEL_COUNT=$OUT_MODEL_COUNT
        echo MODEL_COUNT=$MODEL_COUNT
        echo MOVED_OUT_MODEL_COUNT=$MOVED_OUT_MODEL_COUNT

	cd ${LOC_SCRIPTS}/runs/${OUT_NAME}

	# jobs can be started if the MODE is 1
	PREDICTION_TICKER=0
	submit_jobs_based_on_mode "$MODE" "$LOC_FASTA" "$LOC_FEATURES" "$STOICHIOMETRY" "$LOC_OUT" "$OUT_NAME" "$LOC_SCRIPTS" "$FILE"
	echo "$PREDICTION_TICKER models have been predicted so far."

	if [ "$PREDICTION_TICKER" -ge 5 ]; then
		echo "PREDICTION_TICKER greater than or equal to 5."
		echo "Starting processing of files."
                process_prediction "$LOC_OUT" "$LOC_SCRIPTS" "$OUT_NAME" "$OUT_DIR" "$STORAGE"
		echo "Processing finished."

		# Wait for 3 seconds
    		sleep 3

		# search $LOC_SLURMS for the corresponding slurm file and move it to the $LOC_OUT folder
		matching_files=($(grep -l "$OUT_NAME" ${LOC_SLURMS}/*))
		for file in "${matching_files[@]}"; do
		    mv "$file" "$LOC_OUT/"
		done
		NEW_NAME_DATE=$(add_date "$LOC_OUT")
		mv "${OUT_DIR}/${NEW_NAME_DATE_REP}" "$STORAGE"
		NEW_NAME_DATE_REP=$(add_rep "${STORAGE}/${NEW_NAME_DATE}")
        else
                echo "WAITING FOR ${OUT_NAME} MODELING TO FINISH."
        fi
else
        echo "WAITING FOR ${OUT_NAME} MSA TO FINISH."
fi
echo "Done!"
