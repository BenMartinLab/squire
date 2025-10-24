#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=squire-clean-%A.out

# exit when any command fails
set -e

genome_name=${1:-dm6}
fetch_folder=${2:-squire_fetch}
output_folder=${3:-squire_clean}
repeat_masker_file="${fetch_folder}/${genome_name}_rmsk.txt"

bash squire.sh Clean \
    --rmsk "$repeat_masker_file" \
    --clean_folder "$output_folder" \
    --verbosity
