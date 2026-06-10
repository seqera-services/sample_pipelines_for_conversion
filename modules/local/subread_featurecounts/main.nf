process SUBREAD_FEATURECOUNTS {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::subread=2.1.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/subread:2.1.1--h577a1d6_0' :
        'biocontainers/subread:2.1.1--h577a1d6_0' }"

    input:
    tuple val(meta), path(bam), path(bai)
    path  annotation

    output:
    tuple val(meta), path("*.featureCounts.txt")        , emit: counts
    tuple val(meta), path("*.featureCounts.txt.summary"), emit: summary
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def paired_end = meta.single_end ? '' : '-p'
    """
    featureCounts \\
        $args \\
        -T ${task.cpus} \\
        ${paired_end} \\
        -t exon \\
        -g gene_id \\
        -a ${annotation} \\
        -o ${prefix}.featureCounts.txt \\
        ${bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        subread: \$( featureCounts -v 2>&1 | sed 's/featureCounts v//' )
    END_VERSIONS
    """
}
