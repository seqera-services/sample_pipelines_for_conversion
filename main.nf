#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RNA-seq Analysis Pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Minimal pipeline: FastQC -> STAR alignment -> featureCounts
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Validate input parameters
if (!params.input) {
    error "Please provide a samplesheet via --input"
}
if (!params.star_index) {
    error "Please provide a STAR index directory via --star_index"
}
if (!params.gtf) {
    error "Please provide a GTF annotation file via --gtf"
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC           } from './modules/local/fastqc'
include { STAR_ALIGN       } from './modules/local/star_align'
include { SAMTOOLS_INDEX   } from './modules/local/samtools_index'
include { FEATURECOUNTS    } from './modules/local/featurecounts'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    // Parse samplesheet into channel
    ch_input = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [id: row.sample, single_end: false]
            def reads = [file(row.fastq_1), file(row.fastq_2)]
            [meta, reads]
        }

    // Reference inputs
    ch_star_index = channel.value(file(params.star_index))
    ch_gtf        = channel.value(file(params.gtf))

    // STEP 1: Quality Control
    if (!params.skip_fastqc) {
        FASTQC(ch_input)
    }

    // STEP 2: STAR Alignment
    STAR_ALIGN(ch_input, ch_star_index, ch_gtf)

    // STEP 3: Index BAM
    SAMTOOLS_INDEX(STAR_ALIGN.out.bam)

    // STEP 4: featureCounts quantification
    ch_bam_for_counts = STAR_ALIGN.out.bam
    FEATURECOUNTS(ch_bam_for_counts, ch_gtf)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
