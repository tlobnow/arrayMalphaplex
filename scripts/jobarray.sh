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

# Define the variable S which is equal to the nth line in pdb_list - pdb_list contains the structures and their paths to be analysed.
OUT_NAME=$(awk -v line_num=${SLURM_ARRAY_TASK_ID} 'NR==line_num+1 {print $1}' "$INFO_LIST")
if [ -z "$OUT_NAME" ]; then
  echo "OUT_NAME is empty. Exiting."
  exit 1
fi

STOICHIOMETRY=$(awk -v line_num=${SLURM_ARRAY_TASK_ID} 'NR==line_num+1 {print $2}' "$INFO_LIST")
if [ -z "$STOICHIOMETRY" ]; then
  echo "STOICHIOMETRY is empty. Exiting."
  exit 1
fi

echo "Array-ID:" ${SLURM_ARRAY_TASK_ID}
echo "NAME:" $OUT_NAME
echo "STOICHIOMETRY:" $STOICHIOMETRY
echo "MODE:" $MODE

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
	cd ${LOC_SCRIPTS}/runs/${OUT_NAME}
        ### CHECK MODEL EXISTENCE - IF 0 ARE FOUND, START ALL 5 MODELS IN INDIVIDUAL JOBS OR ALL 5 IN 1 JOB (IF CONSTRUCT SIZE BELOW 2000aa)
        if [[ ($OUT_RLX_MODEL_COUNT -eq 0 ) && ( $MODEL_COUNT -eq 0 ) && ( $OUT_MODEL_COUNT -eq 0 ) && ( $MOVED_OUT_MODEL_COUNT -eq 0 ) ]] ; then
                # jobs can be started if the MODE is 1
		submit_jobs_based_on_mode "$MODE" "$LOC_FASTA" "$LOC_FEATURES" "$STOICHIOMETRY" "$LOC_OUT" "$OUT_NAME" "$LOC_SCRIPTS" "$FILE"
                PREDICTION_STATUS="FAIL"
		echo "submit_jobs_based_on_mode finished."
        else
                ### 5 NEURAL NETWORK MODELS ARE USED - WE LOOP THROUGH 1:5 TO CHECK MODEL PROGRESS
                for i in {1..5}; do
                        evaluate_prediction_for_model "$LOC_OUT" "$OUT_NAME" "$i" "$LOC_SCRIPTS" "$FILE" "$MODE"
                        [ "$PREDICTION_STATUS" = "PASS" ] && ((PREDICTION_TICKER++))
                done
		echo "evaluate_prediction_for_model finished."
		echo "Prediction ticker: $PREDICTION_TICKER"
        fi
	if [ "$PREDICTION_TICKER" -ge 5 ]; then
		echo "PREDICTION_TICKER greater than or equal to 5."
		echo "Starting processing of files."
                process_prediction "$LOC_OUT" "$LOC_SCRIPTS" "$OUT_NAME" "$OUT_DIR" "$STORAGE"
		echo "Processing finished."
        else
                echo "WAITING FOR ${OUT_NAME} MODELING TO FINISH."
        fi
else
        echo "WAITING FOR ${OUT_NAME} MSA TO FINISH."
fi
echo "Done!"
