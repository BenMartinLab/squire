#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=squire-call-%A_%a.out

# exit when any command fails
set -e

script_path=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
if ! [[ -f "${script_path}/squire-call.sh" ]] && [[ -n "$SLURM_JOB_ID" ]]
then
  script_path=$(dirname "$(scontrol show job "$SLURM_JOB_ID" | awk -F '=' '$0 ~ /Command=/ {print $2; exit}')")
fi

index=${SLURM_ARRAY_TASK_ID:-0}
index=$((index+1))
samplesheet=samplesheet.csv
threads=${SLURM_CPUS_PER_TASK:-1}
call_folder=squire_call
extra_parameters=()

# Usage function
usage() {
  echo
  echo "Usage: squire-call.sh [-i <int>] [-s <samplesheet.csv>] [-o <squire_call>] [-p <int>] [-h]"
  echo "  -i: Index of group in samplesheet (default: 1 or SLURM_ARRAY_TASK_ID+1 if present)"
  echo "  -s: Samplesheet file (default: samplesheet.csv)"
  echo "  -o: Output folder (default: squire_call)"
  echo "  -p: Number of threads (default: 1 or SLURM_CPUS_PER_TASK if present)"
  echo "  -h: Show this help and squire Call help"
  echo ""
  echo "Any additional parameters will be passed to squire Call"
  echo ""
  echo "Do not use --group1, --group2, --condition1 or --condition2 parameters for squire Call as they will be set from the samplesheet."
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
    -o | --call_folder)	shift
      call_folder=$1
      ;;
    -p | --pthreads )	shift
      threads=$1
      ;;
    -h | --help)
      usage
      echo ""
      echo ""
      echo ""
      echo "Squire Call help."
      bash "${script_path}/squire.sh" Call -h
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
control_column=$(awk -F ',' \
    'NR == 1 {for (i = 1; i <= NF; i++) if ($i == "control") {print i; exit(0)}}' \
    "$samplesheet")
if [[ -z "$control_column" ]]
then
  >&2 echo "Error: no 'control' column found in samplesheet $samplesheet."
  exit 1
fi

group=$(awk -F ',' -v group_index="$index" \
    '{group=gensub(/(.*)_REP[0-9]*/,"\\1","1",$1)} NR > 1 && !seen[group] {ln++; seen[group]++} ln == group_index {group_index=-1; print group}' \
    "$samplesheet")
if [[ -z "$group" ]]
then
  >&2 echo "Error: no group found for -i parameter '$index'."
  exit 1
fi
control_group=$(awk -F ',' -v group="$group" -v control_column="$control_column" \
    'NR > 1 && $1 ~ "^"group {control_group=gensub(/(.*)_REP[0-9]*/,"\\1","1",$control_column); print control_group; exit(0)}' \
    "$samplesheet")
if [[ -z "$control_group" ]]
then
  >&2 echo "Error: no control group found for experimental group $group."
  exit 1
fi
samplesheet_lines_raw=$(awk -F ',' -v group="$group" \
    'NR > 1 && $1 ~ "^"group {print $0}' \
    "$samplesheet")
readarray -t samplesheet_lines <<< "$samplesheet_lines_raw"
for line in "${samplesheet_lines[@]}"
do
  IFS=',' read -r -a sample_metadata <<< "$line"
  samples+=",${sample_metadata[0]}"
  control_samples+=",${sample_metadata[control_column - 1]}"
done
if [[ -z "${samples}" ]]
then
  >&2 echo "Error: no samples found for group $group using -i parameter '$index'."
  exit 1
else
  samples=${samples:1}
fi
if [[ -z "${control_samples}" ]]
then
  >&2 echo "Error: no control samples found for control group $control_group. Experimental group is $group."
  exit 1
else
  control_samples=${control_samples:1}
fi

# Prevent output file being overwritten when multiple groups are compared.
call_folder="${call_folder}_${group}"
echo "Running squire Call with parameters --pthreads $threads --call_folder $call_folder --condition1 $group --condition2 $control_group --group1 $samples --group2 $control_samples ${extra_parameters[*]}"
bash "${script_path}/squire.sh" Call \
    --pthreads "$threads" \
    --call_folder "$call_folder" \
    --condition1 "$group" \
    --condition2 "$control_group" \
    --group1 "$samples" \
    --group2 "$control_samples" \
    "${extra_parameters[@]}"
