#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G
#SBATCH --output=squire-draw-%A_%a.out

# exit when any command fails
set -e

index=${SLURM_ARRAY_TASK_ID:-0}
index=$((index+1))
threads=${SLURM_CPUS_PER_TASK:-1}

genome_name=${1:-dm6}
fetch_folder=${2:-squire_fetch}
map_folder=${3:-squire_map}
output_folder=${4:-squire_draw}
strandedness=${5:-2}

sample=$(awk -v sample_index="$index" \
    '$0 !~ /[ \t]*#/ {ln++} ln == sample_index {print $1}' samples.txt)
sample="${sample%%[[:cntrl:]]}"

bash squire.sh Draw \
    --fetch_folder "$fetch_folder" \
    --map_folder "$map_folder" \
    --draw_folder "$output_folder" \
    --name "$sample" \
    --build "$genome_name" \
    --strandedness "$strandedness" \
    --pthreads "$threads" \
    --normlib \
    --verbosity
