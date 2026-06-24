process FEATURECOUNTS {
    tag "${meta.id}"
    label 'process_medium'
    publishDir "${params.outdir}/counts", mode: 'copy'

    conda 'bioconda::subread=2.1.1'
    container 'biocontainers/subread:2.1.1--h577a1d6_0'

    input:
    tuple val(meta), path(bam), path(bai)
    path gtf

    output:
    tuple val(meta), path("*.counts.txt"),         emit: counts
    tuple val(meta), path("*.counts.txt.summary"), emit: summary

    script:
    def prefix = "${meta.id}"
    """
    featureCounts \\
        -T ${task.cpus} \\
        -p \\
        -t exon \\
        -g gene_id \\
        -a ${gtf} \\
        -o ${prefix}.counts.txt \\
        ${bam}
    """
}
