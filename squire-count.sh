#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --output=squire-count-%A_%a.out

# exit when any command fails
set -e

script_path=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
if ! [[ -f "${script_path}/squire-count.sh" ]] && [[ -n "$SLURM_JOB_ID" ]]
then
  script_path=$(dirname "$(scontrol show job "$SLURM_JOB_ID" | awk -F '=' '$0 ~ /Command=/ {print $2; exit}')")
fi

index=${SLURM_ARRAY_TASK_ID:-0}
index=$((index+1))
samplesheet=samplesheet.csv
threads=${SLURM_CPUS_PER_TASK:-1}
count_folder=squire_count
extra_parameters=()

# Usage function
usage() {
  echo
  echo "Usage: squire-count.sh [-i <int>] [-s <samplesheet.csv>] [-o <squire_count>] [-p <int>] [-h]"
  echo "  -i: Index of sample in samplesheet (default: 1 or SLURM_ARRAY_TASK_ID+1 if present)"
  echo "  -s: Samplesheet file (default: samplesheet.csv)"
  echo "  -o: Output folder (default: squire_count)"
  echo "  -p: Number of threads (default: 1 or SLURM_CPUS_PER_TASK if present)"
  echo "  -h: Show this help and squire Count help"
  echo ""
  echo "Any additional parameters will be passed to squire Count"
  echo ""
  echo "Do not use --name parameters for squire Count as they will be set from the samplesheet."
}

# Parsing arguments.
while [ "$1" != "" ]; do
  case $1 in
    -i)	shift
      index=$1
      ;;
    -s)	shift
      samplesheet=$1
      ;;
    -o | --count_folder)	shift
      count_folder=$1
      ;;
    -p | --pthreads )	shift
      threads=$1
      ;;
    -h | --help)
      usage
      echo ""
      echo ""
      echo ""
      echo "Squire Count help."
      bash "${script_path}/squire.sh" Count -h
      exit 0
      ;;
    *)
      extra_parameters+=("$1")
  esac
  shift
done

# Validating arguments.
if ! [[ "$index" =~ ^[0-9]+$ ]]
then
  >&2 echo "Error: -i parameter '$index' is not an integer."
  usage
  exit 1
fi
if ! [[ -f "$samplesheet" ]]
then
  >&2 echo "Error: -s file parameter '$samplesheet' does not exists."
  usage
  exit 1
fi

sample=$(awk -F ',' -v sample_index="$index" \
    'NR > 1 && !seen[$1] {ln++; seen[$1]++} ln == sample_index {print $1}' \
    "$samplesheet")

mkdir -p "$count_folder"
if [[ -n "$SLURM_TMPDIR" ]]
then
  slurm_count_folder="${SLURM_TMPDIR}/tmp/${count_folder}"
  original_count_folder="$count_folder"
  count_folder="/tmp/${count_folder}"
  echo "Changing output count folder from $original_count_folder to $count_folder"
  copy_temp_to_output() {
    save_exit=$?
    trap - ERR EXIT SIGINT
    echo
    echo "SQuIRE exit code is $save_exit"
    echo
    echo "Copying output count files from $slurm_count_folder to $original_count_folder"
    rsync -rvt "${slurm_count_folder}"/* "$original_count_folder"
    exit "$save_exit"
  }
  trap 'copy_temp_to_output' ERR EXIT SIGINT
fi

echo "Running squire Count with parameters --pthreads $threads --name $sample --count_folder $count_folder ${extra_parameters[*]}"
bash squire.sh Count \
    --pthreads "$threads" \
    --name "$sample" \
    --count_folder "$count_folder" \
    "${extra_parameters[@]}"
