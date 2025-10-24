#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=1-00:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=32G
#SBATCH --output=squire-map-%A_%a.out

# exit when any command fails
set -e

index=${SLURM_ARRAY_TASK_ID:-0}
index=$((index+1))
threads=${SLURM_CPUS_PER_TASK:-1}

genome_name=${1:-dm6}
fetch_folder=${2:-squire_fetch}
output_folder=${3:-squire_map}
read_length=${4:-50}

sample=$(awk -v sample_index="$index" \
    '$0 !~ /[ \t]*#/ {ln++} ln == sample_index {print $1}' samples.txt)
sample="${sample%%[[:cntrl:]]}"

bash squire.sh Map \
    --read1 "${sample}_R1.fastq.gz" \
    --read2 "${sample}_R2.fastq.gz" \
    --map_folder "$output_folder" \
    --fetch_folder "$fetch_folder" \
    --read_length "$read_length" \
    --name "$sample" \
    --build "$genome_name" \
    --pthreads "$threads" \
    --verbosity
