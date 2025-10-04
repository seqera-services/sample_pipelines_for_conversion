process STAR_ALIGN {
    tag "${meta.id}"
    label 'process_high'
    
    container 'quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:1df389393721fc66f3fd8778ad938ac711951107-0'
    
    input:
    tuple val(meta), path(reads)
    path star_index
    
    output:
    tuple val(meta), path('*.Aligned.sortedByCoord.out.bam'),     emit: bam
    tuple val(meta), path('*.Aligned.sortedByCoord.out.bam.bai'), emit: bai
    tuple val(meta), path('*.Log.final.out'),                     emit: log
    
    script:
    def prefix = "${meta.id}"
    """
    # Extract STAR index
    mkdir -p star_index_dir
    tar -xzf ${star_index} -C star_index_dir --strip-components=1
    
    # Run STAR alignment
    STAR \\
        --runThreadN ${task.cpus} \\
        --genomeDir star_index_dir \\
        --readFilesIn ${reads[0]} ${reads[1]} \\
        --readFilesCommand zcat \\
        --outFileNamePrefix ${prefix}. \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMunmapped Within \\
        --outSAMattributes Standard
    
    # Index BAM file
    samtools index ${prefix}.Aligned.sortedByCoord.out.bam
    """
}
