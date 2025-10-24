#!/bin/bash

if [[ -n "$CC_CLUSTER" ]]
then
  module purge
  module load StdEnv/2023
  module load apptainer/1
fi

container="squire-v0.9.9.9-7c4c79a.sif"
workdir=${SLURM_TMPDIR:-${PWD}}
if [[ -n "$SLURM_TMPDIR" ]]
then
  cp "$container" "$SLURM_TMPDIR"
  container="${SLURM_TMPDIR}/${container}"
else
  workdir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
  trap 'rm -rf "$workdir"; exit' ERR EXIT
fi

apptainer_params=("--containall" "--workdir" "$workdir" "--pwd" "/data" "--bind" "$PWD:/data" \
    "$container")

apptainer run \
  "${apptainer_params[@]}" \
    "$@"
