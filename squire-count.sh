#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem=24G
#SBATCH --output=squire-count-%A_%a.out

# exit when any command fails
set -e

index=${SLURM_ARRAY_TASK_ID:-0}
index=$((index+1))
threads=${SLURM_CPUS_PER_TASK:-1}

genome_name=${1:-dm6}
fetch_folder=${2:-squire_fetch}
clean_folder=${3:-squire_clean}
map_folder=${4:-squire_map}
output_folder=${5:-squire_count}
read_length=${6:-50}
strandedness=${7:-2}

sample=$(awk -v sample_index="$index" \
    '$0 !~ /[ \t]*#/ {ln++} ln == sample_index {print $1}' samples.txt)
sample="${sample%%[[:cntrl:]]}"

mkdir -p "$output_folder"

if [[ -n "$SLURM_TMPDIR" ]]
then
  slurm_output_folder="${SLURM_TMPDIR}/tmp/${output_folder}"
  original_output_folder="$output_folder"
  output_folder="/tmp/${output_folder}"
  echo "Changing output folder from $original_output_folder to $output_folder"
  copy_temp_to_output() {
    save_exit=$?
    trap - ERR EXIT SIGINT
    echo
    echo "SQuIRE exit code is $save_exit"
    echo
    echo "Copying output files from $slurm_output_folder to $original_output_folder"
    rsync -rvt "${slurm_output_folder}"/* "$original_output_folder"
    exit "$save_exit"
  }
  trap 'copy_temp_to_output' ERR EXIT SIGINT
fi

bash squire.sh Count \
    --fetch_folder "$fetch_folder" \
    --clean_folder "$clean_folder" \
    --map_folder "$map_folder" \
    --count_folder "$output_folder" \
    --temp_folder "/tmp" \
    --read_length "$read_length" \
    --name "$sample" \
    --build "$genome_name" \
    --strandedness "$strandedness" \
    --EM auto \
    --pthreads "$threads" \
    --verbosity
