#!/bin/bash

source /home/aperpos/programs/miniconda3/bin/activate
conda install -c conda-forge mamba
mamba create -n pristine_venv -c bioconda -c conda-forge fastqc rcorrector trim-galore bbmap bowtie2 trinity transdecoder hmmer busco

conda activate pristine_venv

echo -e "Downloading assets:\n"

echo -e "Downloading SILVA database, concatenating and grouping, this might take a while..."
cd ${PATH_TO_PRISTINE_ENV}/assets/SILVA
. ./get_silva.sh
cd ${PATH_TO_PRISTINE_ENV}/
echo -e "SILVA database set up.\n"

echo -e "Downloading Pfam database...\n"
cd ${PATH_TO_PRISTINE_ENV}/assets/pfam/
. ./get_pfam.sh
cd ${PATH_TO_PRISTINE_ENV}/
echo -e "Pfam-A.hmm database downloaded.\n"


echo "Downloading TranscriptomeAssemblyTools ..."
cd ${PATH_TO_PRISTINE_ENV}/
echo "git clone https://github.com/harvardinformatics/TranscriptomeAssemblyTools"
git clone https://github.com/harvardinformatics/TranscriptomeAssemblyTools
TAToolsDir="$(dir ${PATH_TO_PRISTINE_ENV}/TranscriptomeAssemblyTools )" 
echo
echo -e "TranscriptomeAssemblyTools succesfully cloned and available at :\n$TAToolsDir \n\n"
echo "Please add this directory to your PATH variable to make it available for pristine. You can do so by:"
echo "Going to your home directory"
echo "Open up the .bash_profile , or the .profile file"
echo "look for the line where 'PATH=' is defined"
echo "add: '$TAToolsDir:' right after the equal sign"
echo "save changes and exit"
echo "type: 'source ./bash_profile' (or /.profile, depends on what you have)"

