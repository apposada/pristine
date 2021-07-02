#!/bin/bash
echo -e "Downloading LSUParc\n"

wget  https://www.arb-silva.de/fileadmin/silva_databases/current/Exports/SILVA_138.1_LSUParc_tax_silva.fasta.gz

echo -e "Downloading SSUParc\n"

wget  https://www.arb-silva.de/fileadmin/silva_databases/current/Exports/SILVA_138.1_SSUParc_tax_silva.fasta.gz

echo -e "Concatenating LSU and SSUParc; this might take a while... \n"

zcat *fasta.gz > SILVA.fasta

rm SILVA_138.1_LSUParc_tax_silva.fasta.gz

rm SILVA_138.1_SSUParc_tax_silva.fasta.gz

echo -e "Indexing the SILVA database; this might take a while..."

source /home/aperpos/programs/miniconda3/bin/activate

conda activate pristine_venv

bowtie2-build SILVA.fast SILVA.fasta.bowtie2

conda deactivate
conda deactivate