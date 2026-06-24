process STAR_ALIGN {
    tag "${meta.id}"
    label 'process_high'
    publishDir "${params.outdir}/star", mode: 'copy'

    conda 'bioconda::star=2.7.11b bioconda::samtools=1.23.1'
    container 'community.wave.seqera.io/library/star_samtools:2.7.11b--e9a0e7be05498e3b'

    input:
    tuple val(meta), path(reads)
    path star_index

    output:
    tuple val(meta), path("*.sortedByCoord.out.bam"), emit: bam
    tuple val(meta), path("*.Log.final.out"),         emit: log_final
    tuple val(meta), path("*.Log.out"),               emit: log_out

    script:
    def prefix = "${meta.id}"
    """
    STAR \\
        --runThreadN ${task.cpus} \\
        --genomeDir ${star_index} \\
        --readFilesIn ${reads[0]} ${reads[1]} \\
        --readFilesCommand zcat \\
        --outFileNamePrefix ${prefix}. \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMunmapped Within \\
        --outSAMattributes Standard
    """
}
