#!/bin/bash -ue
STAR \
    --runThreadN 2 \
    --genomeDir star_index \
    --readFilesIn sample1_R1.fastq.gz sample1_R2.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix yeast_test. \
    --outSAMtype BAM SortedByCoordinate \
    --outSAMunmapped Within \
    --outSAMattributes Standard
