process FEATURECOUNTS {
    tag "$meta.id"
    label 'process_medium'

    conda 'bioconda::subread=2.1.1'
    container 'biocontainers/subread:2.1.1--h577a1d6_0'

    input:
    tuple val(meta), path(bam)
    path gtf

    output:
    tuple val(meta), path("*.counts.txt"),         emit: counts
    tuple val(meta), path("*.counts.txt.summary"), emit: summary
    path "versions.yml",                           emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    featureCounts \\
        ${args} \\
        -T ${task.cpus} \\
        -a ${gtf} \\
        -o ${prefix}.counts.txt \\
        ${bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        subread: \$( featureCounts -v 2>&1 | sed 's/featureCounts v//' )
    END_VERSIONS
    """
}
