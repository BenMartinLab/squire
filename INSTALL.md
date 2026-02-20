# Installing SQuIRE scripts on Alliance Canada

### Steps

1. [Installing of the scripts](#Installing-of-the-scripts)
   1. [Change directory to `project` folder](#Change-directory-to-project-folder)
   2. [Clone repository](#Clone-repository)
   3. [Download SQuIRE container](#Download-SQuIRE-container)
2. [Updating scripts](#Updating-scripts)
3. [Creating container for SQuIRE](#Creating-container-for-SQuIRE)

## Installing of the scripts

### Change directory to project folder

```shell
cd /project/def-bmartin/scripts
```

### Clone repository

```shell
git clone https://github.com/BenMartinLab/squire.git
```

### Download SQuIRE container

> [!NOTE]
> The URL should be updated when Ben create a folder shared by Globus.

```shell
wget https://g-88ccb6.6d81c.5898.data.globus.org/squire/squire-v0.9.9.9-7c4c79a.sif
```

If previous command fails, see [Creating container for SQuIRE](#Creating-container-for-SQuIRE)

## Updating scripts

Go to the squire scripts folder and run `git pull`.

```shell
cd /project/def-bmartin/scripts/squire
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
scp squire-$version-$commit.sif 'narval.computecanada.ca:/project/def-bmartin/Sharing/globus-shared-apps/squire'
```
