#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RNA-seq Analysis Pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Converted from Python script: rnaseq_pipeline.py
    Steps: FastQC -> STAR alignment -> featureCounts quantification
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC           } from './modules/local/fastqc'
include { STAR_ALIGN       } from './modules/local/star_align'
include { SAMTOOLS_INDEX   } from './modules/local/samtools_index'
include { FEATURECOUNTS    } from './modules/local/featurecounts'

workflow {

    // -------------------------------------------------------------------------
    // Input channels
    // -------------------------------------------------------------------------
    ch_reads = channel.fromFilePairs(params.reads, checkIfExists: true)
        .map { sample_id, reads ->
            def meta = [id: sample_id]
            [meta, reads]
        }

    ch_star_index  = channel.fromPath(params.star_index, checkIfExists: true).collect()
    ch_gtf         = channel.fromPath(params.gtf, checkIfExists: true).collect()

    // -------------------------------------------------------------------------
    // STEP 1: Quality control with FastQC
    // -------------------------------------------------------------------------
    FASTQC(ch_reads)

    // -------------------------------------------------------------------------
    // STEP 2: Alignment with STAR
    // -------------------------------------------------------------------------
    STAR_ALIGN(ch_reads, ch_star_index)

    // -------------------------------------------------------------------------
    // STEP 3: Index BAM files
    // -------------------------------------------------------------------------
    SAMTOOLS_INDEX(STAR_ALIGN.out.bam)

    // -------------------------------------------------------------------------
    // STEP 4: Gene quantification with featureCounts
    // -------------------------------------------------------------------------
    ch_bam_bai = STAR_ALIGN.out.bam
        .join(SAMTOOLS_INDEX.out.bai)

    FEATURECOUNTS(ch_bam_bai, ch_gtf)
}
