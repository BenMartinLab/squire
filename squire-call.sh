#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G
#SBATCH --output=squire-call-%A_%a.out

# exit when any command fails
set -e

index=${SLURM_ARRAY_TASK_ID:-0}
index=$((index+1))
threads=${SLURM_CPUS_PER_TASK:-1}

count_folder=${1:-squire_count}
output_folder=${2:-squire_call}
output_format=${3:-pdf}

dataset=$(awk -v dataset_index="$index" \
    '$0 !~ /[ \t]*#/ {ln++} ln == dataset_index {print $1}' dataset.txt)
dataset="${dataset%%[[:cntrl:]]}"
samples=$(awk -v dataset_index="$index" \
    '$0 !~ /[ \t]*#/ {ln++} ln == dataset_index {print $2}' dataset.txt)
samples="${samples%%[[:cntrl:]]}"
condition=$(awk -v dataset_index="$index" \
    '$0 !~ /[ \t]*#/ {ln++} ln == dataset_index {print $3}' dataset.txt)
condition="${condition%%[[:cntrl:]]}"

control=$(awk -v dataset_index="$index" \
    '$0 !~ /[ \t]*#/ {ln++} ln == dataset_index {print $4}' dataset.txt)
control="${control%%[[:cntrl:]]}"
if [ -z "$control" ]
then
  >&2 echo "control column for dataset ${dataset} is empty, exiting..."
  exit 1
fi
control_samples=$(awk -v dataset="${control}" \
    '$1 == dataset {print $2}' dataset.txt)
control_samples="${control_samples%%[[:cntrl:]]}"
if [ -z "$control_samples" ]
then
  >&2 echo "samples column for control dataset ${control} was not found, treated dataset is ${dataset}, exiting..."
  exit 1
fi
control_condition=$(awk -v dataset="${control}" \
    '$1 == dataset {print $3}' dataset.txt)
control_condition="${control_condition%%[[:cntrl:]]}"

bash squire.sh Call \
    --group1 "$samples" \
    --group2 "$control_samples" \
    --condition1 "$condition" \
    --condition2 "$control_condition" \
    --projectname "$dataset" \
    --pthreads "$threads" \
    --output_format "$output_format" \
    --count_folder "$count_folder" \
    --call_folder "$output_folder" \
    --verbosity
