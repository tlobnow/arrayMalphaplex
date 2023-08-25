#!/usr/bin/env bash
#SBATCH --job-name=ARRAY
#SBATCH --time=1:00
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
OUT_NAME=$( head -${SLURM_ARRAY_TASK_ID} $OUT_NAME_LIST | tail -1 )
STOICHIOMETRY=$( head -${SLURM_ARRAY_TASK_ID} $STOICHIOMETRY_LIST | tail -1 )

echo "Array-ID:" ${SLURM_ARRAY_TASK_ID}
echo "NAME:" $OUT_NAME
echo "STOICHIOMETRY:" $STOICHIOMETRY

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

# Split the stoichiometry into individual feature-count pairs and check if all monomers are prepped
IFS='/' read -ra stoichiometry_pairs <<< "$STOICHIOMETRY"
for pair in "${stoichiometry_pairs[@]}"; do
        check_and_process_fasta "${stoichiometry_pairs[@]}"
done
#wait_for_jobs_completion "${MSA_JOBIDS[@]}"

if [ "$CONTINUE" = "TRUE" ]; then
	# Initialize the output directory with the template and set the initial files.
        initialize_run_dir "$LOC_SCRIPTS" "$OUT_NAME"
        # Assess the current status of model files in the output directory.
        assess_model_files "$LOC_OUT" "$OUT_NAME"
else
        log_message "${RED}" "/(-.-)\\ WAITING FOR ${OUT_NAME} MSA TO FINISH."
fi
