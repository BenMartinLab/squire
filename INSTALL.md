# Installing SQuIRE scripts on Alliance Canada

### Steps

1. [Installing of the scripts](#Installing-of-the-scripts)
   1. [Change directory to `projects` folder](#Change-directory-to-projects-folder)
   2. [Clone repository](#Clone-repository)
2. [Updating scripts](#Updating-scripts)
3. [Creating container for SQuIRE](#Creating-container-for-SQuIRE)

## Installing of the scripts

### Change directory to projects folder

```shell
cd ~/projects/def-bmartin/scripts
```

For Rorqual server, use

```shell
cd ~/links/projects/def-bmartin/scripts
```

### Clone repository

```shell
git clone https://github.com/BenMartinLab/squire.git
```

## Updating scripts

Go to the squire scripts folder and run `git pull`.

```shell
cd ~/projects/def-bmartin/scripts/squire
git pull
```

For Rorqual server, use

```shell
cd ~/links/projects/def-bmartin/scripts/squire
git pull
```

## Creating container for SQuIRE

### Create container

To create an [Apptainer](https://apptainer.org) container for SQuIRE, you must use a Linux computer. Ideally, you should have root access on the computer. 

```shell
version=0.9.9.9
commit=7c4c79a0d2882d8b72a5c28c44313b97183b7983
```

```shell
sudo apptainer build --build-arg version=$version --build-arg commit=$commit squire-$version-$commit.sif squire.def
```

On Alliance Canada server, you need to use `fakeroot`. Note that containers created using `fakeroot` may fail.

```shell
module load apptainer
apptainer build --fakeroot --build-arg version=$version --build-arg commit=$commit squire-$version-$commit.sif squire.def
```

### Copy container on Globus

```shell
scp squire-$version-$commit.sif 'narval.computecanada.ca:~/projects/def-bmartin/Sharing/globus-shared-apps/squire'
```
