#!/usr/bin/env nextflow
/*
 * RNA-seq Analysis Pipeline
 * Minimal pipeline: FastQC -> STAR alignment -> featureCounts
 *
 * Requires Nextflow 26.04+
 */

/*
 * PROCESS: FastQC - Quality control on raw reads
 */
process FASTQC {
    tag "${sample_name}_${read_label}"
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(sample_name), val(read_label), path(reads)

    output:
    path("*.{html,zip}")

    when:
    !params.skip_fastqc

    script:
    """
    fastqc \\
        --threads 2 \\
        --quiet \\
        ${reads}
    """
}

/*
 * PROCESS: STAR - Align reads to reference genome
 */
process STAR_ALIGN {
    tag "${sample_name}"
    publishDir "${params.outdir}/star", mode: 'copy'

    input:
    tuple val(sample_name), path(read1), path(read2)
    path(star_index)

    output:
    tuple val(sample_name), path("${sample_name}.Aligned.sortedByCoord.out.bam"), emit: bam
    path("${sample_name}.Log.final.out"), emit: log

    script:
    """
    STAR \\
        --runThreadN ${params.threads} \\
        --genomeDir ${star_index} \\
        --readFilesIn ${read1} ${read2} \\
        --readFilesCommand zcat \\
        --outFileNamePrefix ${sample_name}. \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMunmapped Within \\
        --outSAMattributes Standard
    """
}

/*
 * PROCESS: Index BAM file
 */
process SAMTOOLS_INDEX {
    tag "${sample_name}"
    publishDir "${params.outdir}/star", mode: 'copy'

    input:
    tuple val(sample_name), path(bam)

    output:
    tuple val(sample_name), path(bam), path("${bam}.bai"), emit: bam_bai

    script:
    """
    samtools index ${bam}
    """
}

/*
 * PROCESS: featureCounts - Gene-level quantification
 */
process FEATURECOUNTS {
    tag "${sample_name}"
    publishDir "${params.outdir}/counts", mode: 'copy'

    input:
    tuple val(sample_name), path(bam), path(bai)
    path(annotation)

    output:
    path("${sample_name}.counts.txt"), emit: counts
    path("${sample_name}.counts.txt.summary"), emit: summary

    script:
    """
    featureCounts \\
        -T ${params.threads} \\
        -p \\
        -t exon \\
        -g gene_id \\
        -a ${annotation} \\
        -o ${sample_name}.counts.txt \\
        ${bam}
    """
}

/*
 * Main workflow
 */
workflow {
    main:
    // Validate required parameters
    if (!params.read1) error "Missing required parameter: --read1"
    if (!params.read2) error "Missing required parameter: --read2"
    if (!params.star_index) error "Missing required parameter: --star_index"
    if (!params.annotation) error "Missing required parameter: --annotation"

    // Print pipeline parameters
    log.info """\
        R N A - S E Q   P I P E L I N E
        ================================
        Sample name    : ${params.sample_name}
        Read 1         : ${params.read1}
        Read 2         : ${params.read2}
        STAR index     : ${params.star_index}
        Annotation     : ${params.annotation}
        Output dir     : ${params.outdir}
        Threads        : ${params.threads}
        Skip FastQC    : ${params.skip_fastqc}
        ================================
        """
        .stripIndent()

    // Create input channels
    def read1_ch = channel.fromPath(params.read1, checkIfExists: true)
    def read2_ch = channel.fromPath(params.read2, checkIfExists: true)
    def star_index_ch = channel.fromPath(params.star_index, checkIfExists: true, type: 'dir')
    def annotation_ch = channel.fromPath(params.annotation, checkIfExists: true)

    // Run FastQC on read pairs
    if (!params.skip_fastqc) {
        // Combine reads with labels for FastQC
        def fastqc_input = channel.of(
            [params.sample_name, "R1", params.read1],
            [params.sample_name, "R2", params.read2]
        )
        .map { item -> tuple(item[0], item[1], file(item[2])) }

        FASTQC(fastqc_input)
    }

    // Align reads with STAR
    def reads_ch = read1_ch.combine(read2_ch)
        .map { r1, r2 -> tuple(params.sample_name, r1, r2) }

    STAR_ALIGN(reads_ch, star_index_ch)

    // Index BAM file
    SAMTOOLS_INDEX(STAR_ALIGN.out.bam)

    // Count features
    FEATURECOUNTS(
        SAMTOOLS_INDEX.out.bam_bai,
        annotation_ch
    )

    workflow.onComplete = {
        log.info """\
            Pipeline completed!
            Status    : ${workflow.success ? 'SUCCESS' : 'FAILED'}
            Results   : ${params.outdir}
            Duration  : ${workflow.duration}
            """
            .stripIndent()
    }

    workflow.onError = {
        log.error "Pipeline failed: ${workflow.errorMessage}"
    }
}
