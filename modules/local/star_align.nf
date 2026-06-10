process STAR_ALIGN {
    tag "$meta.id"
    label 'process_high'

    conda 'bioconda::star=2.7.11b bioconda::samtools=1.23.1'
    container 'community.wave.seqera.io/library/star_samtools:2.7.11b_1.23.1--32a4a21049fe8888'

    input:
    tuple val(meta), path(reads)
    path star_index
    path gtf

    output:
    tuple val(meta), path("*.Aligned.sortedByCoord.out.bam"), emit: bam
    tuple val(meta), path("*Log.final.out"),                  emit: log_final
    tuple val(meta), path("*Log.out"),                        emit: log_out
    tuple val(meta), path("*Log.progress.out"),               emit: log_progress
    path "versions.yml",                                      emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    STAR \\
        --runThreadN ${task.cpus} \\
        --genomeDir ${star_index} \\
        --readFilesIn ${reads} \\
        --outFileNamePrefix ${prefix}. \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed 's/STAR_//')
        samtools: \$(samtools --version | head -1 | sed 's/samtools //')
    END_VERSIONS
    """
}
