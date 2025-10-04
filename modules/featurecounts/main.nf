process FEATURECOUNTS {
    tag "$meta.id"
    label 'process_medium'
    
    container 'community.wave.seqera.io/library/subread:2.0.6--1e9c2492f104316c'
    
    input:
    tuple val(meta), path(bam)
    path gtf
    
    output:
    tuple val(meta), path('*.counts.txt')        , emit: counts
    tuple val(meta), path('*.counts.txt.summary'), emit: summary
    path 'versions.yml'                           , emit: versions
    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    featureCounts \\
        -T ${task.cpus} \\
        -p \\
        -t exon \\
        -g gene_id \\
        -a ${gtf} \\
        -o ${prefix}.counts.txt \\
        ${args} \\
        ${bam}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        featurecounts: \$(featureCounts -v 2>&1 | grep featureCounts | sed 's/featureCounts v//')
    END_VERSIONS
    """
}
