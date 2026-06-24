process SAMTOOLS_INDEX {
    tag "${meta.id}"
    label 'process_low'
    publishDir "${params.outdir}/star", mode: 'copy'

    conda 'bioconda::samtools=1.23.1'
    container 'biocontainers/samtools:1.23.1--h4dc53f1_0'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bai"), emit: bai

    script:
    """
    samtools index ${bam}
    """
}
