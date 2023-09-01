# PROTEIN COMPLEX PREDICTION ON MPCDF RAVEN

## Table of Contents
- [First Time Setup](#first-time-setup)
- [Normal Session](#normal-session)
- [Advanced Features](#advanced-features)
- [Troubleshooting](#troubleshooting)

## First Time Setup

1. **Download and Install Miniconda**

    ```bash
    curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod +x Miniconda3-latest-Linux-x86_64.sh
    ./Miniconda3-latest-Linux-x86_64.sh
    ```

2. **Create a New Environment**

    ```bash
    conda create --name malpha python=3.8
    ```

3. **Clone Required GitHub Repositories and Run Setup Script**

    ```bash
    git clone https://github.com/FreshAirTonight/af2complex.git
    git clone https://github.com/tlobnow/arrayMalphaplex.git
    cd arrayMalphaplex
    ./setup.sh
    ```

4. **Adjust the paths according to your installation**

    - Open `PATHS` in the scripts directory and check if the paths correspond to your installation, otherwise adjust accordingly..

## Normal Session

1. **Specify Run Mode and User Parameters**

    - Edit `PATHS` to specify the `RUN_MODE` (single, multiple, or matrix-like setups), `MODE` (1 for job submission, 2 for progress information), and other settings.
    - Edit `user_parameters.sh` to enter setup components (monomers) and the stoichiometry information

2. **Submit Array Jobs**

    Run the `submit_array.sh` script:

    ```bash
    ./submit_array.sh
    ```

3. **Monitor Job Progress**

    - Use `check_squeue.sh` or `squeue.sh` to view currently running jobs.
    - Start `./submit_array.sh` to start/continue steps of the pipeline: 
	- preparation of feature files --> `/ptmp/$USER/feature_files`
        - prediction of models --> `/ptmp/$USER/output_files`
        - processing and moving output files for downstream analysis --> `$MAIN/output_files`

    The INFO_LIST` contains a summary of output names and stoichiometries for submitted setups and is provided in `$MAIN/scripts/lists`

5. **Retrieve and Process Results**

    Once the jobs are complete, the output folders and summary CSV files will be moved to their final storage locations.

    - Final output files will be moved into `$MAIN/output_files` and receive a `repX` suffix if the same setup is generated repeatedly (it is advised to repeat setup runs with new random seeds)
    - The log file contains all information about the run coordination
    - `RUN_DETAILS` will contain all model setting used to generate the respective models
    - All predicted models are stored in `MODELS`
    - The summary CSV files are in the respective `CSV` folder (two files are generated, one contains all models including recycles, the other file is limited to the final five models)
    - The JSON files are provided in the respective `JSON` folder
    - PDB files from recycle rounds are stored in the respective `recycles` folder


## Advanced Features

- To adjust the model prediction settings, adjust `01_user_parameters.inc` in the `$MAIN/scripts/template` folder.

## Troubleshooting

- If you encounter issues with missing files, ensure that the paths specified in `PATHS` are correct.
- For issues related to SLURM job submission, check the SLURM logs.

