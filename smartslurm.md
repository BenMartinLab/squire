# SQuIRE on Alliance Canada

This repository contains scripts to run [SQuIRE](https://github.com/wyang17/SQuIRE) on Alliance Canada servers.

To install the scripts on Alliance Canada servers and create containers, see [INSTALL.md](INSTALL.md)

### Steps

1. [Create samplesheet file](#Create-samplesheet-file)
2. [Prepare working environment](#Prepare-working-environment)
3. [Copy genome for SQuIRE](#Copy-genome-for-SQuIRE)
4. [Run SQuIRE pipeline](#Run-SQuIRE-pipeline)
6. [Run SQuIRE Call](#Run-SQuIRE-Call)
8. [Output](#Output)

## Create samplesheet file

Create the samplesheet file using the instructions for nf-core RNA-seq pipeline. See [Samplesheet for RNA-seq pipeline](https://nf-co.re/rnaseq/3.22.2/docs/usage/#samplesheet-input)

To get the output from [squire Call](https://github.com/wyang17/SQuIRE?tab=readme-ov-file#squire-call), you must provide a `control` column containing the name of the control samples associated with the experimental samples, when applicable.
This is an additional column not normally present in the samplesheet used by nf-core's RNA-seq pipeline.
Any samples without a value in the `control` column will not be compared with `squire Call`.

[Here is an example of a samplesheet file](samplesheet.csv)

> [!NOTE]
> Run this command on your samplesheet to remove any carriage return character that is usually added by Excel.

```shell
dos2unix "$samplesheet"
```

## Prepare working environment

Save project to a variable

```shell
project=/project/def-bmartin
```

Add SQuIRE and SmartSlurm scripts folder to your PATH

```shell
export PATH=$project/scripts/squire:$PATH
export PATH=$project/scripts/SmartSlurm/bin:$PATH
```

### Set additional variables

> [!IMPORTANT]
> Change `samplesheet.csv` by your actual samplesheet filename.

```shell
samplesheet=samplesheet.csv
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
genomes_folder=$project/scripts/squire/genomes
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

## Run SQuIRE pipeline

```shell
runAsPipeline \
    "$project/scripts/squire/squire-pipeline.sh -s samplesheet.csv -l $read_length -g $genome -S $strandedness" \
    "sbatch --account=def-bmartin --time=3:00:00 --cpus-per-task=1 --mem=8G" \
    noTmp \
    run
```

This will run SQuIRE `Map`, `Count`, `Draw` and `Call` automatically.

## Output

The output folders are:
* squire_count
* squire_call_*
* squire_draw
* squire_map
