#!/bin/bash -ue
fastqc \
    --threads 2 \
    --quiet \
    sample1_R1.fastq.gz
