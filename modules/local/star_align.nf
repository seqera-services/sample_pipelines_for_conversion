process STAR_ALIGN {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::star=2.7.11b bioconda::samtools=1.23.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:hostadd' :
        'quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:1df389393721fc66f3fd8778ad938ac711951107-0' }"

    input:
    tuple val(meta), path(reads)
    path  index
    path  gtf

    output:
    tuple val(meta), path("*.Aligned.sortedByCoord.out.bam"), emit: bam
    tuple val(meta), path("*.Aligned.sortedByCoord.out.bam.bai"), emit: bai
    tuple val(meta), path("*.Log.final.out")               , emit: log_final
    tuple val(meta), path("*.Log.out")                     , emit: log_out
    tuple val(meta), path("*.Log.progress.out")            , emit: log_progress
    tuple val(meta), path("*.SJ.out.tab")                  , emit: sj
    path "versions.yml"                                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    STAR \\
        --runThreadN $task.cpus \\
        --genomeDir $index \\
        --readFilesIn ${reads} \\
        --readFilesCommand zcat \\
        --outFileNamePrefix ${prefix}. \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMunmapped Within \\
        --outSAMattributes Standard \\
        $args

    samtools index ${prefix}.Aligned.sortedByCoord.out.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed "s/STAR_//")
        samtools: \$(samtools --version | head -1 | sed 's/samtools //')
    END_VERSIONS
    """
}
