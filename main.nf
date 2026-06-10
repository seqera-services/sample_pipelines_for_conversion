#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RNA-seq Analysis Pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Converted from: rnaseq_pipeline.py
    Steps: FastQC -> STAR alignment -> samtools index -> featureCounts
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC               } from './modules/local/fastqc/main'
include { STAR_ALIGN           } from './modules/local/star_align/main'
include { SAMTOOLS_INDEX       } from './modules/local/samtools_index/main'
include { SUBREAD_FEATURECOUNTS } from './modules/local/subread_featurecounts/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    // Create input channel from sample sheet or direct params
    if (params.input) {
        ch_reads = channel
            .fromSamplesheet('input')
            .map { meta, fastq_1, fastq_2 ->
                def single_end = fastq_2 ? false : true
                [ meta + [single_end: single_end], single_end ? [fastq_1] : [fastq_1, fastq_2] ]
            }
    } else {
        ch_reads = channel.of(
            [
                [id: params.sample_name, single_end: false],
                [file(params.read1, checkIfExists: true), file(params.read2, checkIfExists: true)]
            ]
        )
    }

    // Reference files
    ch_star_index  = file(params.star_index, checkIfExists: true)
    ch_gtf         = file(params.gtf, checkIfExists: true)

    // STEP 1: Quality control with FastQC
    if (!params.skip_fastqc) {
        FASTQC(ch_reads)
    }

    // STEP 2: Align reads with STAR
    STAR_ALIGN(
        ch_reads,
        ch_star_index,
        ch_gtf
    )

    // STEP 3: Index BAM files
    SAMTOOLS_INDEX(STAR_ALIGN.out.bam)

    // STEP 4: Gene quantification with featureCounts
    ch_bam_bai = STAR_ALIGN.out.bam
        .join(SAMTOOLS_INDEX.out.bai)

    SUBREAD_FEATURECOUNTS(
        ch_bam_bai,
        ch_gtf
    )
}


