#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=squire-fetch-%A.out

# exit when any command fails
set -e

threads=${SLURM_CPUS_PER_TASK:-1}

genome_name=${1:-dm6}
output_dir=${2:-squire_fetch}

bash squire.sh Fetch \
    --build "$genome_name" \
    --fetch_folder "$output_dir" \
    --fasta \
    --rmsk \
    --chrom_info \
    --gene \
    --pthreads "$threads" \
    --verbosity
