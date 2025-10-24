#!/bin/bash
#SBATCH --account=def-bmartin
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --output=star-index-%A.out

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

genome_name=${1:-dm6}
output_dir=${2:-squire_fetch}
star_fasta="${output_dir}/${genome_name}.chromFa/${genome_name}.fa"
star_index="${output_dir}/${genome_name}_STAR"

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

echo "Generating STAR index for Drosophila Melanogaster genome"
mkdir -p "$star_index"
apptainer exec \
  "${apptainer_params[@]}" \
    STAR \
    --runThreadN "$threads" \
    --runMode genomeGenerate \
    --genomeFastaFiles "$star_fasta" \
    --genomeDir "$star_index"
