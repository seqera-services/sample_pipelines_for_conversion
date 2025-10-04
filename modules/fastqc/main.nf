process FASTQC {
    tag "$meta.id"
    label 'process_medium'
    
    container 'community.wave.seqera.io/library/fastqc:0.12.1--aa717e1a9d994d74'
    
    input:
    tuple val(meta), path(reads)
    
    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip
    path 'versions.yml'            , emit: versions
    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    fastqc \\
        --threads ${task.cpus} \\
        --outdir . \\
        ${args} \\
        ${reads}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$(fastqc --version | sed 's/FastQC v//')
    END_VERSIONS
    """
}
