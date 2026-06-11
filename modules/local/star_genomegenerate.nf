process STAR_GENOMEGENERATE {
    tag "$fasta"
    label 'process_high'

    conda "bioconda::star=2.7.11b bioconda::samtools=1.23.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:hostadd' :
        'quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:1df389393721fc66f3fd8778ad938ac711951107-0' }"

    input:
    path fasta
    path gtf

    output:
    path "star"         , emit: index
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p star

    STAR \\
        --runMode genomeGenerate \\
        --genomeDir star \\
        --genomeFastaFiles $fasta \\
        --sjdbGTFfile $gtf \\
        --runThreadN $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed "s/STAR_//")
        samtools: \$(samtools --version | head -1 | sed 's/samtools //')
    END_VERSIONS
    """
}
