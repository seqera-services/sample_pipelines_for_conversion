process STAR_ALIGN {
    tag "$meta.id"
    label 'process_high'
    
    container 'community.wave.seqera.io/library/samtools_star:86807538d25ae5a9'
    
    input:
    tuple val(meta), path(reads)
    path index
    
    output:
    tuple val(meta), path('*Aligned.sortedByCoord.out.bam')    , emit: bam
    tuple val(meta), path('*Aligned.sortedByCoord.out.bam.bai'), emit: bai
    tuple val(meta), path('*Log.final.out')                     , emit: log_final
    tuple val(meta), path('*Log.out')                           , emit: log_out
    tuple val(meta), path('*Log.progress.out')                  , emit: log_progress
    path 'versions.yml'                                          , emit: versions
    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reads_command = reads[0].toString().endsWith('.gz') ? 'zcat' : 'cat'
    
    """
    STAR \\
        --runThreadN ${task.cpus} \\
        --genomeDir ${index} \\
        --readFilesIn ${reads[0]} ${reads[1]} \\
        --readFilesCommand ${reads_command} \\
        --outFileNamePrefix ${prefix}. \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMunmapped Within \\
        --outSAMattributes Standard \\
        ${args}
    
    samtools index ${prefix}.Aligned.sortedByCoord.out.bam
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed 's/STAR_//')
        samtools: \$(samtools --version | grep samtools | sed 's/samtools //')
    END_VERSIONS
    """
}
