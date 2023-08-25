#!/usr/bin/env bash

source ./PATHS
source ./FUNCTIONS

case "$RUN_MODE" in
	"SINGLE")
		source "${LOC_SCRIPTS}"/SINGLE.sh
		;;
	"MULTI")
		FILE_A=MYD88_MOUSE
		N_A=1
		N_B=1
		STOICHIOMETRY=${FILE_A}:${N_A}/${FILE}:${N_B}
		OUT_NAME=${FILE_A}_x${N_A}_${FILE}_x${N_B}
		OUT_NAME_LIST=${LOC_LISTS}/${FOLDER}_outnames.txt
		for i in ${LOC_FASTA}/${FOLDER}/*.fasta; do
			echo "${FILE_A}"_x"${N_A}"_"$(basename -a -s .fasta $i)"_x"${N_B}"
		done > "$OUT_NAME_LIST"

		STOICHIOMETRY_LIST=${LOC_LISTS}/${FOLDER}_stoichiometries.txt
		for i in ${LOC_FASTA}/${FOLDER}/*.fasta; do
			echo "${FILE_A}":"${N_A}"/"$(basename -a -s .fasta $i)":"${N_B}"
		done > "$STOICHIOMETRY_LIST"
		;;
	*"MATRIX")
		source "${LOC_SCRIPTS}"/MATRIX.sh
		;;
	*)
		echo "Please adjust the run settings in 01_SOURCE.inc"
		;;
esac

NUM=$(wc -l < "${OUT_NAME_LIST}")
NUM=$((NUM+1))
echo "Number of files:" "${NUM}"

# Create missing run directories and copy templates
while read -r line; do
	run_dir="${LOC_SCRIPTS}/runs/${line}"
	if [ ! -d "$run_dir" ]; then
		echo "creating folder $line"
		cp -r "${LOC_SCRIPTS}/template" "$run_dir"
		# Remove template folder if it was copied into the new folder by mistake
		[ -d "${run_dir}/template" ] && rm -rf "${run_dir}/template"
	else
		echo "checking file $line!"
	fi
done < "$OUT_NAME_LIST"

cp "${LOC_FASTA}/${FOLDER}"/*.fasta "${LOC_FASTA}"
