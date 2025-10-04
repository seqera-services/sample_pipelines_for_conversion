process FEATURECOUNTS {
    tag "${meta.id}"
    label 'process_medium'
    
    container 'quay.io/biocontainers/subread:2.0.1--hed695b0_0'
    
    input:
    tuple val(meta), path(bam)
    path annotation_gtf
    
    output:
    tuple val(meta), path('*.counts.txt'),         emit: counts
    tuple val(meta), path('*.counts.txt.summary'), emit: summary
    
    script:
    def prefix = "${meta.id}"
    """
    featureCounts \\
        -T ${task.cpus} \\
        -p \\
        -t exon \\
        -g gene_id \\
        -a ${annotation_gtf} \\
        -o ${prefix}.counts.txt \\
        ${bam}
    """
}
