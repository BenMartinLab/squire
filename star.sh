#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --output=star-%A.out

# exit when any command fails
set -e

# load required modules
if [[ -n "$CC_CLUSTER" ]]
then
  module purge
  module load StdEnv/2023
  module load apptainer/1
fi

threads=${SLURM_CPUS_PER_TASK:-1}

script_path=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
if ! [[ -f "${script_path}/nfcore-rnaseq.sh" ]] && [[ -n "$SLURM_JOB_ID" ]]
then
  script_path=$(dirname "$(scontrol show job "$SLURM_JOB_ID" | awk -F '=' '$0 ~ /Command=/ {print $2; exit}')")
fi

containers=("${script_path}"/squire-*.sif)
if [[ -f "${containers[0]}" ]]
then
  container=${containers[0]}
else
  >&2 echo "Error: no containers were found in current folder, exiting..."
  exit 1
fi

# Copy container to SLURM_TMPDIR for faster access.
workdir=${SLURM_TMPDIR:-${PWD}}
if [[ -n "$SLURM_TMPDIR" ]]
then
  cp "$container" "$SLURM_TMPDIR"
  container=$(basename "$container")
  container="${SLURM_TMPDIR}/${container}"
else
  workdir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
  trap 'rm -rf "$workdir"; exit' ERR EXIT
fi

apptainer_params=("--containall" "--workdir" "$workdir" "--pwd" "/data" \
    "--bind" "$PWD:/data")

echo "Running STAR $*"
apptainer exec \
  "${apptainer_params[@]}" \
  "$container" \
    STAR \
    --runThreadN "$threads" \
    "$@"
