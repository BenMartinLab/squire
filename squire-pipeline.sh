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

samples_raw=$(awk -F ',' 'NR > 1 && !seen[$1] {seen[$1]++; print $1}' "$samplesheet")
readarray -t samples <<< "$samples_raw"
# genome_bed is used by runAsPipeline for resource estimation
# shellcheck disable=SC2034
genome_bed=$(head -n 1 <<< "$genome_bed_files")

for sample in "${samples[@]}"
do
  samplesheet_lines_raw=$(awk -F ',' -v sample="$sample" \
      'NR > 1 && $1 == sample {print $0}' \
      "$samplesheet")
  readarray -t samplesheet_lines <<< "$samplesheet_lines_raw"
  reads_1=
  reads_2=
  for line in "${samplesheet_lines[@]}"
  do
    readarray -d ',' -t sample_metadata <<< "$line"
    reads_1+=",${sample_metadata[1]}"
    reads_2+=",${sample_metadata[2]}"
  done
  reads_1=${reads_1:1}
  reads_2=${reads_2:1}
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
