#!/usr/bin/env bash

# ==== User Input Section ====
# You should only need to modify variables in this section.

# Load essential paths and functions
source ./PATHS
source ./FUNCTIONS

# Output file to store information. Do not change.
#INFO_LIST=${LOC_LISTS}/${FOLDER}_INFO.txt

# Remove the file if it already exists from previous runs
# (optional, based on your needs)
[ -f $INFO_LIST ] && rm $INFO_LIST

# ==== Script Starts Here ====
# Initialization
[ ! -f $INFO_LIST ] && echo -e "OUT_NAME\tSTOICHIOMETRY" > $INFO_LIST

# Case for single protein complex setup
if [ "$RUN_MODE" == "SINGLE" ]; then
    # You should enter the stoichiometry and output name here
    STOICHIOMETRY=MYD88_MOUSE:3
    OUT_NAME=MYD88_MOUSE_x3

    # Write to the information list
    echo -e "${OUT_NAME}\t${STOICHIOMETRY}" >> "$INFO_LIST"

# Case for multiple protein complex setup
elif [ "$RUN_MODE" == "MULTI" ]; then
    # You should enter these details
    A=MYD88_MOUSE  # Name of the monomer A
    N_A=1          # Number of copies of monomer A
    N_B=1          # Number of copies of monomer B

    # Automatically generate stoichiometry and output name for each fasta file in the folder
    for i in ${LOC_FASTA}/${FOLDER}/*.fasta; do
        file_name=$(basename -a -s .fasta $i)
        echo -e "${A}_x${N_A}_${file_name}_x${N_B}\t${A}:${N_A}/${file_name}:${N_B}" >> "$INFO_LIST"
    done

# Case for matrix-like setup
elif [ "$RUN_MODE" == "MATRIX" ]; then
    # You should enter these details
    A=MYD88_MOUSE       # Name of the monomer A
    B=IRAK4_MOUSE       # Name of the monomer B
    START_A=2; END_A=3  # Range for monomer A copies
    START_B=2; END_B=3  # Range for monomer B copies

    # Automatically generate stoichiometry and output name
    for i in $(seq $START_A $END_A); do
        for j in $(seq $START_B $END_B); do
            echo -e "${A}_x${i}_${B}_x${j}\t${A}:${i}/${B}:${j}" >> "$INFO_LIST"
        done
    done
else
    echo "Please adjust the run settings in user_parameters.sh"
fi

# ==== That's it. Nothing to adjust below  ====

# Count lines to get NUM (subtract 1 for header)
NUM=$(( $(wc -l < "$INFO_LIST") - 1 ))
echo "Number of structures:" $NUM

# add NUM column to INFO_LIST that enumerates each row
awk -F'\t' 'BEGIN {OFS="\t"} NR==1 {print $0, "NUM"} NR>1 {print $0, NR-1}' \
  "$INFO_LIST" > temp && mv temp "$INFO_LIST"

# Iterate through each line of the combined list (skipping the header), creating or checking run directories.
while IFS=$'\t' read -r OUT_NAME STOICHIOMETRY ROW_NUM; do
    [[ "$OUT_NAME" == "OUT_NAME" ]] && continue  # Skip header
    run_dir="${LOC_SCRIPTS}/runs/${OUT_NAME}"
    if [ ! -d "$run_dir" ]; then
        echo "Creating folder $OUT_NAME"; cp -r "${LOC_SCRIPTS}/template" "$run_dir"
        [[ -d "${run_dir}/template" ]] && rm -rf "${run_dir}/template"  # Remove mistakenly copied template folder
    else
        echo "Checking file $OUT_NAME!"
    fi
done < "$INFO_LIST"

# Copy fasta files
[ -d "${LOC_FASTA}/${FOLDER}" ] && cp "${LOC_FASTA}/${FOLDER}"/*.fasta "${LOC_FASTA}"

