#!/bin/bash 
#error handling
set -e
# set -u not compatible with -h? i.e. may need to find a way that it doesnt run if and only if any of d a b or s are not defined.

## STEP 00: PREPARATION. FQ VARIABLE ASSIGNATION, PATH ASSIGNATION, PRESENTATION##
while getopts :d:a:b:s:hn aflag; do
        case $aflag in
                h)
                echo
                echo
                echo "*** PRISTINE *** (pseudo)workflow: from pair-end fq to assembly including multiple quality steps"
                echo " "
                echo "Heavily borrowing from Harvard's good practices for de novo transcriptome assembly. All credit is theirs:"
                echo "https://informatics.fas.harvard.edu/best-practices-for-de-novo-transcriptome-assembly-with-trinity.html"
                echo " "
                echo " "
                echo "Usage: pristine.sh -d [path,DIR] -r1 [FASTQ/.gz] -r2 [FASTQ/.gz] -s [STRING]"
                echo " "
                echo "Options:"
                echo "-h: HELP             Show brief help"
                echo "-d: RUNPATH          Path where the run will take place"
                echo "-a: READ1            Paired-end read 1 file, can be softlink. Real path will be parsed"
                echo "-b: READ2            Paired-end read 2 file, can be softlink. Real path will be parsed"
                echo "-s: RUNNAME          Name or identifier of the run. Used in trinity, busco, and others"
                echo "-n: ONLYCLEANUP  Finishes the script after fastq quality filtering, trimming and correction"
                exit 0
                ;;
                d) RUNPATH=$OPTARG;;
                a) READ1=$OPTARG;;
                b) READ2=$OPTARG;;
                s) RUNNAME=$OPTARG;;
                n) ONLYCLEANUP=1;;
                ?) echo
                echo
                echo "*** PRISTINE *** (pseudo)workflow: from pair-end fq to assembly including multiple quality steps"
                echo " "
                echo "Heavily borrowing from Harvard's good practices for de novo transcriptome assembly. All credit is theirs:"
                echo "https://informatics.fas.harvard.edu/best-practices-for-de-novo-transcriptome-assembly-with-trinity.html"
                echo " "
                echo " "
                echo "Usage: pristine.sh -d [path,DIR] -r1 [FASTQ/.gz] -r2 [FASTQ/.gz] -s [STRING]"
                echo " "
                echo "Options:"
                echo "-h: HELP             Show brief help"
                echo "-d: RUNPATH          Path where the run will take place"
                echo "-a: READ1            Paired-end read 1 file, can be softlink. Real path will be parsed"
                echo "-b: READ2            Paired-end read 2 file, can be softlink. Real path will be parsed"
                echo "-s: RUNNAME          Name or identifier of the run. Used in trinity, busco, and others"
                echo "-n: ONLY_FQ_CLEANUP  Finishes the script after fastq quality filtering, trimming and correction"
                echo
                echo
                echo
                echo "ERROR:"
                echo "Unrecognised argument: $OPTARG . Stopping, check and try again." && exit ;;
        esac
done


## MAJOR VARIABLE PARSING ##
# clear out positional parameters
set --

# grabbed from Dave Dopson's answer in stackOverflow: https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel/246128#246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
# end of snippet 

sourcedirectory=$DIR
workingdirectory=$RUNPATH
fq1=$(realpath $READ1)
fq2=$(realpath $READ2)
organism_sample_id=$RUNNAME
only_fq_cleanup=$ONLYCLEANUP
FCHA=`date +'%Y/%m/%d' | perl -pe "s/\///g"`
echo
echo
echo
echo "*** PRISTINE *** (pseudo)workflow: from pair-end fq to assembly including multiple quality steps"
echo
echo
echo
echo "working directory is: $workingdirectory"
echo
echo
echo "FASTQ files are: $fq1 , $fq2"
echo
echo
echo "The specified flags are:"
echo    "Run path=$workingdirectory"
echo    "Run name=$organism_sample_id"
echo    "Read 1=$READ1"
echo    "Read 2=$READ2"
echo    "date=$FCHA"
echo
echo

source /home/aperpos/.bashrc
eval "$(conda shell.bash hook)"


## STEP 01: FASTQC ##
echo "## STEP 01: FASTQC ##"
echo
echo "creating directory 01_raw_fastqc"
mkdir 01_raw_fastqc
echo
echo "entering fastqc directory"
cd 01_raw_fastqc
echo "path right now is:"
pwd
echo
echo
echo "activating virtual environment"
source /home/aperpos/programs/miniconda3/bin/activate
conda activate trinity_venv
echo "Starting quality assessment using fastqc tool"
{
        echo A
        fastqc --threads 6 --outdir ./ $fq1
        fastqc --threads 6 --outdir ./ $fq2
} >pristine_01_fastqc.o 2>&1  || exit 1

echo "done quality assesment using fastqc tool."
conda deactivate
conda deactivate
echo
echo
echo "now out of virtual environment"
cd $workingdirectory
echo
echo
echo

## STEP 02: RCORRECTOR, 3 CORRECTIONS/KMER ##
echo "## STEP 02: RCORRECTOR, 3 CORRECTIONS/KMER ##"
echo
echo "creating directory 02_rcorrector"
mkdir 02_rcorrector
echo
echo "entering rcorrector directory"
cd 02_rcorrector
echo "path right now is:"
pwd
echo
echo
echo "starting rcorrector, 3 max corrections per kmer"
{
        echo A
        perl ~/programs/Rcorrector/run_rcorrector.pl -t 12 -1 $fq1 -2 $fq2 -maxcorK 3
} >pristine_02_rcorrector.o 2>&1  || exit 1

echo "done rcorrector."
echo
echo "assigning rcorrector outputs to pipeline variables fq1_rcor and fq2_rcor"
fq1_rcor=$(realpath $(find . -name *1.cor*))
fq2_rcor=$(realpath $(find . -name *2.cor*))
cd $workingdirectory
echo
echo
echo

## STEP 03: REMOVE UNWANTED UNCORRECTED READS ##
echo "## STEP 03: REMOVE UNWANTED UNCORRECTED READS ##"
echo
echo "creating directory 03_python_filter_uncorrected"
mkdir 03_python_filter_uncorrected
echo
module purge
module load Python/2.7.11-foss-2016a

echo "entering pythonfilteruncorrected directory"
cd 03_python_filter_uncorrected
echo "path right now is:"
pwd
echo
echo
echo "starting removal of unwanted uncorrected reads; cleaning of the fastq"
echo "python /home/aperpos/programs/TranscriptomeAssemblyTools/FilterUncorrectabledPEfastq.py --left_reads $fq1_rcor --right_reads $fq1_rcor -s $RUNNAME"
{
        python /home/aperpos/programs/TranscriptomeAssemblyTools/FilterUncorrectabledPEfastq.py --left_reads $fq1_rcor --right_reads $fq2_rcor -s $RUNNAME
} > pristine_03_PyRemoveUnwanted.o 2>&1  || exit 1

echo "done removal of uncorrected reads"
echo

echo "assigning rcorrector outputs to pipeline variables fq1_corrected and fq2_corrected"
fq1_corrected=$(realpath $(find . -name unfixrm*1.cor*))
fq2_corrected=$(realpath $(find . -name unfixrm*2.cor*))
cd $workingdirectory
module purge
echo
echo
echo

## STEP 04: TRIM GALORE! ##
echo "## STEP 04: TRIM GALORE! ##"
echo
echo "creating directory 04_trimgalore"
mkdir 04_trimgalore
echo
echo "entering trimgalore directory"
cd 04_trimgalore
echo "path right now is:"
pwd
echo
echo
echo "activating virtual environment"
source /home/aperpos/programs/miniconda3/bin/activate
conda activate trinity_venv
echo "starting 'Trim Galore!'"
{
        echo A
        trim_galore --paired --retain_unpaired --phred33 --output_dir trimmed_reads --length 36 -q 5 --stringency 1 -e 0.1 $fq1_corrected $fq2_corrected
} >pristine_04_trimgalore.o 2>&1  || exit 1

echo "done 'Trim Galore!'."
conda deactivate
conda deactivate
echo
echo
echo "now out of virtual environment"
echo
echo
echo "assigning rcorrector outputs to pipeline variables fq1_trimg and fq2_trimg"
fq1_trimg=$(realpath $(find . -name *val_1.fq*))
fq2_trimg=$(realpath $(find . -name *val_2.fq*))
cd $workingdirectory
echo
echo
echo

## STEP 05: BBDUK (BABADOOK ( ͡° ͜ʖ ͡°))
echo "## STEP 05: BBDUK ##"
echo
echo "creating directory 05_bbduk"
mkdir 05_bbduk
echo
echo "entering bbduk territory :o"
cd 05_bbduk
echo "we are in:"
pwd
echo
echo
echo "about to remove remaining adapters"
echo "starting bbduk ( ͡° ͜ʖ ͡°)"
{
        echo A
        bbduk.sh in1=$fq1_trimg in2=$fq2_trimg ref=${sourcedirectory}/assets/ADAPTER_CONTAMINANTS/bbduk_adapters_contaminants_list.fa ktrim=r k=23 mink=11 hdist=1 tpe tbo out1=${organism_sample_id}_clean_1.fq out2=${organism_sample_id}_clean_2.fq
} >pristine_05_bbduk.o 2>&1  || exit 1

echo "done bbduk.( ͡~ ͜ʖ ͡°)"
echo
echo "assigning adapter-free reads to pipeline variables fq1_bbdu and fq2_bbdu"
fq1_bbdu=$(realpath $(find . -name *_clean_1.fq))
fq2_bbdu=$(realpath $(find . -name *_clean_2.fq))
cd $workingdirectory
echo
echo
echo

## STEP 06: REMOVE RIBOSOMAL RNA ##
echo "## STEP 06: REMOVE RIBOSOMAL RNA ##"
echo
echo "creating directory 06_remove_rrna"
mkdir 06_remove_rrna
echo
echo "entering antirRNA directory"
cd 06_remove_rrna
echo "path right now is:"
pwd
echo
echo
echo "starting alignment against SILVA database to keep unaligned (==non-ribosomal) reads"
{
        echo A
        bowtie2 --quiet --very-sensitive-local --phred33  -x ${sourcedirectory}/assets/SILVA/SILVA_indexed/SILVA.fasta.bowtie2 -1 $fq1_bbdu -2 $fq2_bbdu --threads 12 --met-file ${organism_sample_id}_bowtie2_metrics.txt --al-conc-gz blacklist_paired_aligned_${organism_sample_id}.fq.gz --un-conc-gz blacklist_paired_unaligned_${organism_sample_id}.fq.gz  --al-gz blacklist_unpaired_aligned_${organism_sample_id}.fq.gz --un-gz blacklist_unpaired_unaligned_${organism_sample_id}.fq.gz -S ${organism_sample_id}_alignment.sam
} >pristine_06_remove_rrna.o 2>&1  || exit 1

echo "done removal of rrna. keep blacklist_paired_unaligned."
echo
echo "For practical reasons, removing now the sam file only."
echo "rm ${organism_sample_id}_alignment.sam"
rm ${organism_sample_id}_alignment.sam
echo
echo "done removing sam."
echo
echo
echo "assigning paired unaligned reads to pipeline variables fq1_noribo and fq2_noribo"
fq1_noribo=$(realpath $(find . -name blacklist_paired_unaligned_*1.gz))
fq2_noribo=$(realpath $(find . -name blacklist_paired_unaligned_*2.gz))
cd $workingdirectory
echo
echo
echo

# STEP 07: FASTQC CLEAN ##
echo "## STEP 07: FASTQC CLEAN ##"
echo
echo "creating directory 07_clean_fastqc"
mkdir 07_clean_fastqc
echo
echo "entering fastqc directory"
cd 07_clean_fastqc
echo "path right now is:"
pwd
echo
echo
echo "activating virtual environment"
source /home/aperpos/programs/miniconda3/bin/activate
conda activate trinity_venv
echo "Starting quality assessment using fastqc tool"
{
        echo A
        fastqc --threads 6 --outdir ./ $fq1_noribo
        fastqc --threads 6 --outdir ./ $fq2_noribo
} >pristine_07_clean_fastqc.o 2>&1  || exit 1

echo "done quality assesment using fastqc tool."

conda deactivate
conda deactivate
echo
echo
echo "now out of virtual environment"
cd $workingdirectory
echo
echo

if [[ "$only_fq_cleanup" == "1" ]]; then
echo "Parameter -n (==only_fq_cleanup) specified. Hence the script finishes here, after cleaning up the fastqs."
echo "Have a happy parsing and a nice day. Now exiting."
exit 0
fi


## STEP 08: ***TRINITY*** ##
echo "## STEP 08: ***TRINITY*** ##"
echo
echo "creating directory 08_trinity_denovo"
mkdir 08_trinity_denovo
echo
echo "entering trinity directory"
cd 08_trinity_denovo
echo "path right now is:"
pwd
echo
echo
echo "activating virtual environment"
echo
echo
echo "Starting denovo transcriptome assembly using Trinity"
source /home/aperpos/programs/miniconda3/bin/activate
conda activate trinity_venv
{
        echo A
        Trinity --seqType fq --max_memory 50G --left $fq1_noribo --right $fq2_noribo --include_supertranscripts --CPU 8 --no_bowtie --trimmomatic --output trinity_denovo_${organism_sample_id} --full_cleanup
} >pristine_08_trinity.o 2>&1  || exit 1

echo "done de novo assembly using Trinity."
echo
echo "assigning denovo assembly(s) to pipeline variable(s) denovo_full, denovo_super"
denovo_full=$(realpath $(find . -name *Trinity.fasta))
denovo_super=$(realpath $(find . -name *Trinity.SuperTrans.fasta))
denovo_super_name=${denovo_super##*/}
/home/aperpos/programs/miniconda3/envs/trinity_venv/opt/trinity-2.12.0/util/TrinityStats.pl $denovo_full
conda deactivate
conda deactivate
echo
echo
echo "now out of virtual environment"
cd $workingdirectory
echo
echo

## STEP 09: TRANSDECODER ##
echo "## STEP 09: TRANSDECODER ##"
echo
echo "creating directory 09_transdecoder"
mkdir 09_transdecoder
echo
echo "entering transdecoder directory"
cd 09_transdecoder
echo "path right now is:"
pwd
echo
echo
echo "activating virtual environment"
echo
echo
source /home/aperpos/programs/miniconda3/bin/activate
{
        echo A
        conda activate transdecoder_venv
        TransDecoder.LongOrfs -t $denovo_super
        conda activate hmmer_venv
        hmmscan --cpu 8 --domtblout pfam.domtblout /home/aperpos/ECHI_HEMI_SPECIES/pfam/Pfam-A.hmm ${denovo_super_name}.transdecoder_dir/longest_orfs.pep
        conda deactivate
        blastp -db /home/aperpos/ECHI_HEMI_SPECIES/uniprot_sprot/uniprot_sprot.fasta -query ${denovo_super_name}.transdecoder_dir/longest_orfs.pep -max_target_seqs 1 -outfmt 6 -evalue 1e-5 -num_threads 12 > blastp.outfmt6
        TransDecoder.Predict -t $denovo_super --retain_pfam_hits pfam.domtblout --retain_blastp_hits blastp.outfmt6 --single_best_only
        conda deactivate
        conda deactivate
} >pristine_09_transdecoder.o 2>&1  || exit 1

echo
echo
echo "now out of virtual environment"
echo "assigning transdecoder output to pipeline variable tdpep"
tdpep=$(realpath $(find ./ -name *.transdecoder.pep))
cd $workingdirectory
echo
echo

## STEP 10: VARIOUS COMPLETENESS ##
echo "## STEP 10: VARIOUS COMPLETENESS ##"
echo
echo "creating directory 10_busco"
mkdir 10_busco
echo
echo "entering BUSCO directory"
cd 10_busco
echo "path right now is:"
pwd
echo
echo
echo "activating virtual environment"
echo
echo
source /home/aperpos/programs/miniconda3/bin/activate
conda activate busco_venv
echo "starting BUSCO completeness analysis"
{
        echo A
        busco -i $tdpep -f -m prot -l metazoa -o ${organism_sample_id}_busco_out
} >pristine_10_busco.o 2>&1  || exit 1
echo "done BUSCO completeness analysis"
conda deactivate
conda deactivate
echo
echo
echo "now out of virtual environment"
cd $workingdirectory
echo
echo
echo "Generating stats of the run: trinity and busco..."
# TRINITY STATS #
echo -e "PRISTINE PSEUDOPIPELINE: QUALITY, ASSEMBLY AND COMPLETENESS STATS\n\nRUN ${organism_sample_id}\n\n*** TRINITY DENOVO ASSEMBLY ***" > FINAL_METRICS.txt
cat 08_trinity_denovo/*assembly.metrics >> FINAL_METRICS.txt
# BUSCO OF FULL DENOVO TRANSCRIPTOME #

# BUSCO OF FULL TRANSDECODER PREDICTED PROTEOME #

# BUSCO OF SUPERTRANSCRIPT TRANSCRIPTOME # 

# BUSCO OF SUPERTRANSCRIPT PREDICTED PROTEOME #
echo -e "\n\n*** BUSCO COMPLETENESS ANALYSIS OF: SUPERTRANCRIPT-DERIVED, SINGLE-BEST-ONLY, TRANSDECODER-PREDICTED PROTEINS ***\n" >> FINAL_METRICS.txt
cat 10_busco/*busco_out/short_summary*busco_out.txt >> FINAL_METRICS.txt
echo ""
echo
cd
echo
echo "Done."