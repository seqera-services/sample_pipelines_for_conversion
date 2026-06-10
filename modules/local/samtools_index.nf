process SAMTOOLS_INDEX {
    tag "$meta.id"
    label 'process_low'

    conda 'bioconda::samtools=1.23.1'
    container 'biocontainers/samtools:1.23.1--h4dc53f1_0'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bai"), emit: bai
    path "versions.yml",            emit: versions

    script:
    """
    samtools index ${bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | head -1 | sed 's/samtools //')
    END_VERSIONS
    """
}
