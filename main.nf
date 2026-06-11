#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RNA-seq Pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Minimal RNA-seq analysis pipeline: FastQC -> STAR alignment -> featureCounts
    Converted from WDL implementation.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Include modules
include { FASTQC           } from './modules/local/fastqc'
include { STAR_GENOMEGENERATE } from './modules/local/star_genomegenerate'
include { STAR_ALIGN       } from './modules/local/star_align'
include { FEATURECOUNTS    } from './modules/local/featurecounts'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    // Create input channel from samplesheet
    ch_input = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample, single_end: false]
            def reads = [file(row.fastq_1), file(row.fastq_2)]
            [meta, reads]
        }

    // Reference files
    ch_gtf   = channel.value(file(params.gtf))
    ch_fasta = params.fasta ? channel.value(file(params.fasta)) : channel.value([])

    //
    // MODULE: Generate STAR index (if not provided)
    //
    if (params.star_index) {
        ch_star_index = channel.value(file(params.star_index))
    } else {
        STAR_GENOMEGENERATE(ch_fasta, ch_gtf)
        ch_star_index = STAR_GENOMEGENERATE.out.index
    }

    //
    // MODULE: FastQC - Quality control
    //
    FASTQC(ch_input)

    //
    // MODULE: STAR - Alignment
    //
    STAR_ALIGN(ch_input, ch_star_index, ch_gtf)

    //
    // MODULE: featureCounts - Quantification
    //
    FEATURECOUNTS(STAR_ALIGN.out.bam, ch_gtf)
}
