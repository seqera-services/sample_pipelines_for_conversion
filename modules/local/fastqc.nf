process FASTQC {
    tag "${meta.id}_${meta.read}"
    label 'process_low'
    
    container 'biocontainers/fastqc:v0.11.9_cv8'
    
    input:
    tuple val(meta), path(fastq)
    
    output:
    tuple val(meta), path('*.html'), emit: html
    tuple val(meta), path('*.zip'),  emit: zip
    
    script:
    """
    fastqc \\
        --outdir . \\
        --threads ${task.cpus} \\
        ${fastq}
    """
}
