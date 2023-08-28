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

3. **Activate the Environment**

    ```bash
    conda activate malpha
    ```
    To automatically activate the environment at login, add `conda activate malpha` to your `~/.bashrc` file.

4. **Clone Required GitHub Repositories and Run Setup Script**

    ```bash
    git clone https://github.com/FreshAirTonight/af2complex.git
    git clone https://github.com/tlobnow/malphaplex.git
    cd malphaplex
    ./setup.sh
    ```

## Normal Session

1. **Activate the Environment and Update Scripts**

    ```bash
    conda activate malpha
    cd malphaplex
    git pull
    ```

2. **Specify Run Mode and User Parameters**

    Edit the `PATHS` and `user_parameters.sh` files to specify the `RUN_MODE`, `MODE`, and other settings.

3. **Submit Array Jobs**

    Run the `submit_array.sh` script:

    ```bash
    ./submit_array.sh
    ```

4. **Monitor Job Progress**

    - Use `check_squeue.sh` or `squeue.sh` to view currently running jobs.
    - Check the `feature_files` folder for the prepared features.

5. **Retrieve and Process Results**

    Once the jobs are complete, the output folders and summary CSV files will be moved to their final storage locations.

## Advanced Features

- To specify custom stoichiometries and output names, edit the `user_parameters.sh` file.
- For more advanced settings, refer to the inline comments in the `PATHS` and `user_parameters.sh` files.

## Troubleshooting

- If you encounter issues with missing files, ensure that the paths specified in `PATHS` are correct.
- For issues related to SLURM job submission, check the SLURM logs.

