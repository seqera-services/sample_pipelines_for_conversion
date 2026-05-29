process STAR_ALIGN {
    tag "${meta.id}"
    label 'process_high'

    conda "bioconda::star=2.7.11b bioconda::samtools=1.23.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:7e2a3354e04e78013d8e00f3629cf4da11204a1d-0' :
        'biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:7e2a3354e04e78013d8e00f3629cf4da11204a1d-0' }"

    input:
    tuple val(meta), path(reads)
    path  star_index

    output:
    tuple val(meta), path("*.bam"),     emit: bam
    tuple val(meta), path("*.bam.bai"), emit: bai
    tuple val(meta), path("*Log.final.out"), emit: log_final
    tuple val(meta), path("*Log.out"),       emit: log_out
    path "versions.yml",                     emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    STAR \\
        --runThreadN ${task.cpus} \\
        --genomeDir ${star_index} \\
        --readFilesIn ${reads} \\
        --readFilesCommand zcat \\
        --outFileNamePrefix ${prefix}. \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMunmapped Within \\
        --outSAMattributes Standard \\
        $args

    samtools index ${prefix}.Aligned.sortedByCoord.out.bam

    # Rename to cleaner filename
    mv ${prefix}.Aligned.sortedByCoord.out.bam ${prefix}.sorted.bam
    mv ${prefix}.Aligned.sortedByCoord.out.bam.bai ${prefix}.sorted.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed -e "s/STAR_//g")
        samtools: \$(samtools --version | head -1 | sed 's/samtools //')
    END_VERSIONS
    """
}
