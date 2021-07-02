source /home/aperpos/programs/miniconda3/bin/activate
conda install -c conda-forge mamba
mamba create -n pristine_venv -c bioconda -c conda-forge fastqc rcorrector trim-galore bbmap bowtie2 trinity busco transdecoder

conda activate pristine_venv

echo -e "Downloading assets:\n"
echo -e "Downloading SILVA database, concatenating and grouping, this might take a while..."
cd ${PATH_TO_PRISTINE_ENV}/assets/SILVA
. ./get_silva.sh
	#wget  https://www.arb-silva.de/fileadmin/silva_databases/current/Exports/SILVA_138.1_LSUParc_tax_silva.fasta.gz
	#wget  https://www.arb-silva.de/fileadmin/silva_databases/current/Exports/SILVA_138.1_SSUParc_tax_silva.fasta.gz
	#zcat *fasta.gz > SILVA.fasta
	#rm SILVA_138.1_LSUParc_tax_silva.fasta.gz
	#rm SILVA_138.1_SSUParc_tax_silva.fasta.gz
	#echo -e "Indexing the SILVA database...""
	#source /home/aperpos/programs/miniconda3/bin/activate
	#conda activate pristine_venv
	#bowtie2-build -i bvlablabalabla etc.

cd ${PATH_TO_PRISTINE_ENV}/
echo -e "SILVA database downloaded.\n"



echo -e "Downloading Pfam database...\n"
cd ${PATH_TO_PRISTINE_ENV}/assets/pfam/
. ./get_pfam.sh
	# wget https:/pfam
cd ${PATH_TO_PRISTINE_ENV}/
echo -e "Pfam-A.hmm database downloaded.\n"



echo "Downloading TranscriptomeAssemblyTools ..."
cd ${PATH_TO_PRISTINE_ENV}/
echo "git clone https://github.com/harvardinformatics/TranscriptomeAssemblyTools"
git clone https://github.com/harvardinformatics/TranscriptomeAssemblyTools
TAToolsDir="$(dir ${PATH_TO_PRISTINE_ENV}/TranscriptomeAssemblyTools )" 
echo
echo -e "TranscriptomeAssemblyTools succesfully cloned and available at :\n$TAToolsDir \n\n"
echo "Please add this directory to your PATH to make it available for pristine"

# mamba install -c bioconda -c conda-forge fastqc
# mamba install -c rcorrector
# install transcriptomeassemblytools goes here
# mamba install -c bioconda -c conda-forge trim-galore
# mamba install -c bioconda -c conda-forge bbmap
# mamba install -c bioconda -c conda-forge bowtie2
# mamba install -c bioconda -c conda-forge trinity
# mamba install -c bioconda -c conda-forge busco
# mamba install -c bioconda -c conda-forge transdecoder

