#!/bin/bash -ue
featureCounts \
    -T 2 \
    -p \
    -t exon \
    -g gene_id \
    -a genes.gtf \
    -o yeast_test.counts.txt \
    yeast_test.Aligned.sortedByCoord.out.bam
