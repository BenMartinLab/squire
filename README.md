# SQuIRE on Alliance Canada

This repository contains scripts to run [SQuIRE](https://github.com/wyang17/SQuIRE) on Alliance Canada servers.

To install the scripts on Alliance Canada servers and create containers, see [INSTALL.md](INSTALL.md)

### Steps

1. [Create samplesheet file](#Create-samplesheet-file)
2. [Prepare working environment](#Prepare-working-environment)
3. [Copy genome for SQuIRE](#Copy-genome-for-SQuIRE)
4. [Run SQuIRE Map](#Run-SQuIRE-Map)
5. [Run SQuIRE Count](#Run-SQuIRE-Count)
6. [Run SQuIRE Call](#Run-SQuIRE-Call)
7. [Run SQuIRE Draw](#Run-SQuIRE-Draw)
8. [Output](#Output)

## Create samplesheet file

Create the samplesheet file using the instructions for nf-core RNA-seq pipeline. See [Samplesheet for RNA-seq pipeline](https://nf-co.re/rnaseq/3.22.2/docs/usage/#samplesheet-input)

To use `squire-call.sh`, you must provide a `control` column containing the name of the control samples associated with the experimental samples, when applicable.
This is an additional column not normally present in the samplesheet used by nf-core's RNA-seq pipeline.
Any samples without a value in the `control` column will not be compared with `squire-call.sh`.

[Here is an example of a samplesheet file](samplesheet.csv)

> [!NOTE]
> Run this command on your samplesheet to remove any carriage return character that is usually added by Excel.

```shell
dos2unix "$samplesheet"
```

## Prepare working environment

Add SQuIRE scripts folder to your PATH

```shell
export PATH=/project/def-bmartin/scripts/squire:$PATH
```

### Set additional variables

> [!IMPORTANT]
> Change `samplesheet.csv` by your actual samplesheet filename.

```shell
samplesheet=samplesheet.csv
```

```shell
samples_array=$(awk -F ',' \
    'NR > 1 && !seen[$1] {ln++; seen[$1]++} END {print "0-"ln-1}' \
    "$samplesheet")
```

```shell
group_array=$(awk -F ',' \
    'NR == 1 {for (i = 1; i <= NF; i++) if ($i == "control") {control_column=i; break}}
    {group=gensub(/[^_]*_(.*)_REP[0-9]**/,"\\1","1",$1)} NR > 1 && !seen[group] {ln++; seen[group]++; {if ($control_column != "") {array=array","ln-1}}}
    END {print substr(array, 2)}' \
    "$samplesheet")
```

> [!IMPORTANT]
> Change `100` by the actual read length of your FASTQ files.

```shell
read_length=100
```

> [!IMPORTANT]
> Change `0` by the actual strandedness of your sequences. See [SQuIRE Count documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-count). 

```shell
strandedness=0
```

## Copy genome for SQuIRE

First, set the location of the genomes.

```shell
genomes_folder=/project/def-bmartin/scripts/squire/genomes
```

Then, locate the genome that you want. A good command is to use `ls` to find the desired main genome.

```shell
ls $genomes_folder
```

For example, if you want a human genome, you can look at the `hg38` sub-folder.

```shell
ls $genomes_folder/hg38
```

You can save the genome name as a variable to simplify later commands.

> [!IMPORTANT]
> Change `hg38` by the genome you want to use.

```shell
genome=hg38
```

Once you have located the genome that you wish to use, I recommend to copy it to the scratch folder along other files like FASTQ.

```shell
cp -r $genomes_folder/$genome/squire_fetch .
cp -r $genomes_folder/$genome/squire_clean .
```

## Run SQuIRE Map

See [SQuIRE Map documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-map)

```shell
sbatch --array=$samples_array squire-map.sh \
    -s $samplesheet \
    --read_length $read_length \
    --verbosity
```

## Run SQuIRE Count

See [SQuIRE Count documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-count)

```shell
sbatch --array=$samples_array squire-count.sh \
    -s $samplesheet \
    --read_length $read_length \
    --strandedness $strandedness \
    --verbosity
```

## Run SQuIRE Call

See [SQuIRE Call documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-call)

```shell
sbatch --array="$group_array" squire-call.sh \
    -s $samplesheet \
    --output_format pdf \
    --verbosity
```

## Run SQuIRE Draw

See [SQuIRE Draw documentation](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-draw)

```shell
sbatch --array=$samples_array squire-draw.sh \
    -s $samplesheet \
    --build $genome \
    --strandedness $strandedness \
    --normlib \
    --verbosity
```

## Output

The most interesting output folder are:
* squire_call
* squire_draw
