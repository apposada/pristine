#!/bin/bash
source /home/aperpos/programs/miniconda3/bin/activate
conda activate pristine_venv
wget ftp://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam31.0/Pfam-A.hmm.gz
gunzip Pfam-A.hmm.gz
hmmpress Pfam-A.hmm
conda deactivate
conda deactivate