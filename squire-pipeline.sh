#!/bin/bash

# exit when any command fails
set -e

script_name=$(basename "${BASH_SOURCE[0]}")
script_path=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
if ! [[ -f "${script_path}/squire-map.sh" ]] && [[ -n "$SLURM_JOB_ID" ]]
then
  script_path=$(dirname "$(scontrol show job "$SLURM_JOB_ID" | awk -F '=' '$0 ~ /Command=/ {print $2; exit}')")
fi

samplesheet=samplesheet.csv
read_length=
genome=
strandedness=0

# Usage function
usage() {
  echo
  echo "Usage: $script_name [-s <samplesheet.csv>] -l <read_length> -g <genome> [-S <int>] [-h]"
  echo "  -s: Samplesheet file (default: samplesheet.csv)"
  echo "  -l: Read length (required)"
  echo "  -g: UCSC designation for genome build, eg. 'hg38' (required)"
  echo "  -S: Sequences strandedness (default: 0)"
  echo "  -h: Show this help"
}

# Parsing arguments.
while getopts 's:l:g:S:h' OPTION; do
  case "$OPTION" in
    s)
       samplesheet="$OPTARG"
       ;;
    l)
       read_length="$OPTARG"
       ;;
    g)
       genome="$OPTARG"
       ;;
    S)
       strandedness="$OPTARG"
       ;;
    h)
       usage
       exit 0
       ;;
    :)
       usage
       exit 1
       ;;
    ?)
       usage
       exit 1
       ;;
  esac
done

# Validating arguments.
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
  >&2 echo "Warning: no 'control' column found in samplesheet $samplesheet, squire Call will not be run"
fi
if ! [[ "$read_length" =~ ^[0-9]+$ ]]
then
  >&2 echo "Error: -l parameter '$read_length' is not an integer."
  usage
  exit 1
fi
genome_bed_files=$(find squire_clean -name "${genome}*.bed")
if [[ -z "$genome_bed_files" ]]
then
  >&2 echo "Error: -g genome parameter '$genome' files could not be found in 'squire_clean' folder."
  usage
  exit 1
fi
if ! [[ "$strandedness" =~ ^[0-9]+$ ]]
then
  >&2 echo "Error: -S parameter '$strandedness' is not an integer."
  usage
  exit 1
fi

parse_samplesheet_column() {
  local column=$1
  local samplesheet_lines=$2
  raw_values=$(awk -F ',' -v column="$column" \
      '!seen[$column] {seen[$column]++; print $column}' \
      <<< "$samplesheet_lines")
  readarray -t values <<< "$raw_values"
  IFS=,; echo "${values[*]}"
}

samples_raw=$(awk -F ',' 'NR > 1 && !seen[$1] {seen[$1]++; print $1}' "$samplesheet")
readarray -t samples <<< "$samples_raw"
# genome_bed is used by runAsPipeline for resource estimation
# shellcheck disable=SC2034
genome_bed=$(head -n 1 <<< "$genome_bed_files")

for sample in "${samples[@]}"
do
  samplesheet_lines=$(awk -F ',' -v sample="$sample" \
      'NR > 1 && $1 == sample {print $0}' \
      "$samplesheet")
  reads_1=$(parse_samplesheet_column 2 "$samplesheet_lines")
  reads_2=$(parse_samplesheet_column 3 "$samplesheet_lines")
  if [[ -n "$reads_2" ]] && ! [[ "$reads_2" =~ \,* ]]
  then
    reads_2_parameters=("--read2" "$reads_2")
  else
    reads_2=""
    reads_2_parameters=()
  fi

  #@1,0,squire-map,genome_bed,reads_1.reads_2,sbatch --cpus-per-task=24 --mem=60G --time=3:00:00
  squire.sh Map \
      --pthreads 24 \
      --name "$sample" \
      --read1 "$reads_1" \
      "${reads_2_parameters[@]}" \
      --read_length "$read_length" \
      --verbosity

  #@2,1,squire-count,genome_bed,reads_1.reads_2,sbatch --mem=10G --time=3:00:00
  squire.sh Count \
      --name "$sample" \
      --read_length "$read_length" \
      --strandedness "$strandedness" \
      --verbosity

  #@3,1,squire-draw,genome_bed,reads_1.reads_2,sbatch --mem=8G --time=3:00:00
  squire.sh Draw \
      --name "$sample" \
      --build "$genome" \
      --strandedness "$strandedness" \
      --normlib \
      --verbosity
done

if [[ -n "$control_column" ]]
then
  groups_raw=$(awk -F ',' \
      '{group=gensub(/(.*)_REP[0-9]*/,"\\1","1",$1)} NR > 1 && !seen[group] {seen[group]++; print group}' \
      "$samplesheet")
  readarray -t groups <<< "$groups_raw"

  for group in "${groups[@]}"
  do
    control_group=$(awk -F ',' -v group="$group" -v control_column="$control_column" \
        'NR > 1 && $1 ~ "^"group {control_group=gensub(/(.*)_REP[0-9]*/,"\\1","1",$control_column); print control_group; exit(0)}' \
        "$samplesheet")
    if [[ -z "$control_group" ]]
    then
      >&2 echo "Info: no control group found for group $group, skipping squire Call."
      continue
    fi

    samplesheet_lines=$(awk -F ',' -v group="$group" \
        'NR > 1 && $1 ~ "^"group {print $0}' \
        "$samplesheet")
    group_samples=$(parse_samplesheet_column 1 "$samplesheet_lines")
    control_samples=$(parse_samplesheet_column "$control_column" "$samplesheet_lines")
    reads_1=$(parse_samplesheet_column 2 "$samplesheet_lines")
    reads_2=$(parse_samplesheet_column 3 "$samplesheet_lines")
    if [[ -z "${group_samples}" ]]
    then
      >&2 echo "Warning: no samples found for group $group, skipping squire Call."
      continue
    fi
    if [[ -z "${control_samples}" ]]
    then
      >&2 echo "Warning: no control samples found for control group $control_group, skipping squire Call. Experimental group is $group."
      continue
    fi
    if [[ "$reads_2" =~ \,* ]]
    then
      reads_2=""
    fi

    # Prevent output file being overwritten when multiple groups are compared.
    call_folder="squire_call_${group}"
    #@4,2,squire-call,genome_bed,reads_1.reads_2,sbatch --cpus-per-task=2 --mem=8G --time=3:00:00
    squire.sh Call \
        --pthreads 2 \
        --call_folder "$call_folder" \
        --condition1 "$group" \
        --condition2 "$control_group" \
        --group1 "$group_samples" \
        --group2 "$control_samples" \
        --output_format pdf \
        --verbosity
  done
fi
