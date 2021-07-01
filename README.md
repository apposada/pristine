# pristine 🧬✨
This is a workflow for automated de novo transcriptome assembly following state of the art quality standards. It is currently in development and it is intended for personal use (at the moment).

This workflow heavily borrows from Harvard's good practices for de novo transcriptome assembly, plus adding some steps of quality control and improvement. Credits for the flow design goes to them:
https://informatics.fas.harvard.edu/best-practices-for-de-novo-transcriptome-assembly-with-trinity.html

The idea is to first clean up the FASTQs from low quality reads, adapter sequences and ribosomal RNA (using rcorrector, trimgalore, bbduk), and subsequently create a de novo assembly using Trinity. Fastqc runs at the beginning and after quality steps to provide an orientation of how good the quality improval went. It also includes transdecoder and BUSCO steps to provide a set of predicted proteins ready for annotation or orthology calling.

Important info:

Please note that this is in development. I am learning a lot in bioinformatics and how to code as I develop this. Many path references are specific of my current setup so at the moment it is not available for direct execution.

pristine is intended to run in a hpc system, preferrably using a workload manager to allocate a whole node, due to the memory-intense steps of bowtie2 and Trinity.

pristine requires a conda environment with all the software that is used (perhaps a package recipe could be created in the future).

pristine starts from a pair ofpaired-end read FASTQs and assembles de novo using trinity. It currently does not support multiple samples as separate files. Thus, the pair of FASTQs can be a single sample or a concatenations of multiple samples and conditions.

More soon!
