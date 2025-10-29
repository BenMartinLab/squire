# SQuIRE on Alliance Canada

This repository contains scripts to run [SQuIRE](https://github.com/wyang17/SQuIRE) on Alliance Canada servers.

To install the scripts on Alliance Canada servers and create containers, see [INSTALL.md](INSTALL.md)

### Steps

1. [Add SQuIRE scripts folder to your PATH](#Add-SQuIRE-scripts-folder-to-your-PATH)
2. [Download SQuIRE container](#Download-SQuIRE-container)
3. [Create samples and dataset files](#Create-samples-and-dataset-files)
4. [Download genome for SQuIRE](#Download-genome-for-SQuIRE)
5. [Create index of genome](#Create-index-of-genome)
6. [Run SQuIRE Clean](#Run-SQuIRE-Clean)
7. [Run SQuIRE Map](#Run-SQuIRE-Map)
8. [Run SQuIRE Count](#Run-SQuIRE-Count)
9. [Run SQuIRE Call](#Run-SQuIRE-Call)
10. [Run SQuIRE Draw](#Run-SQuIRE-Draw)
11. [Output](#Output)

## Add SQuIRE scripts folder to your PATH

```shell
export PATH=~/projects/def-bmartin/scripts/squire:$PATH
```

For Rorqual server, use

```shell
export PATH=~/links/projects/def-bmartin/scripts/squire:$PATH
```

## Download SQuIRE container

> [!NOTE]
> The URL should be updated when Ben create a folder shared by Globus.

```shell
wget https://g-88ccb6.6d81c.5898.data.globus.org/squire/squire-v0.9.9.9-7c4c79a.sif
```

## Create samples and dataset files

See [samples.txt](samples.txt) and [dataset.txt](dataset.txt) for examples. Any lines starting with `#` are ignored.

The `samples.txt` file should contain the following columns. Additional columns are ignored.
1. Sample name.

The sample names must match FASTQ files. Here are the expected FASTQ filenames:
1. ${sample_name}_R1.fastq.gz
2. ${sample_name}_R2.fastq.gz

The `dataset.txt` file should contain the following columns.
1. Dataset name.
2. Sample names separated by commas.
3. Dataset's experimental condition.
4. Name of control dataset, if applicable. If dataset is a control, lease empty.

You should save the number of samples and dataset in variables to use later with `sbatch`.

```shell
samples_array=$(awk '$0 !~ /[ \t]*#/ {ln++} END {print "0-"ln-1}' samples.txt)
dataset_array=$(awk '{ if ($0 !~ /[ \t]*#/) {ln++; if ($4 != "") {array=array","ln-1}}} END {print substr(array, 2)}' dataset.txt)
```

## Download genome for SQuIRE

Use UCSC designation for genome build, eg. 'hg38'.

```shell
genome=hg38
```

Use script squire-fetch.sh to download the genome for SQuIRE. See [SQuIRE Fetch documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-fetch)


```shell
bash squire-fetch.sh $genome
```

## Create index of genome

```shell
sbatch star-index.sh $genome
```

## Run SQuIRE Clean

See [SQuIRE Clean documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-clean)

```shell
sbatch squire-clean.sh $genome
```

## Run SQuIRE Map

See [SQuIRE Map documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-map)

```shell
sbatch --array="$samples_array" squire-map.sh
```

## Run SQuIRE Count

See [SQuIRE Count documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-count)

```shell
sbatch --array="$samples_array" squire-count.sh
```

## Run SQuIRE Call

See [SQuIRE Call documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-call)

```shell
sbatch --array="$dataset_array" squire-call.sh
```

## Run SQuIRE Draw

See [SQuIRE Draw documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-draw)

```shell
sbatch --array="$samples_array" squire-draw.sh
```

## Output

The most interesting output folder are:
* squire_call
* squire_draw
