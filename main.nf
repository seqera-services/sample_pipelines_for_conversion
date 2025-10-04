#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RNA-seq Pipeline - Nextflow DSL2
    Converted from WDL
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Minimal RNA-seq pipeline: FastQC -> STAR alignment -> featureCounts
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC         } from './modules/local/fastqc'
include { STAR_ALIGN     } from './modules/local/star_align'
include { FEATURECOUNTS  } from './modules/local/featurecounts'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow RNASEQ {
    
    take:
    reads_ch        // channel: [ val(meta), [ path(read1), path(read2) ] ]
    star_index      // path: star_index.tar.gz
    annotation_gtf  // path: annotation.gtf
    
    main:
    
    // Create channel for individual reads for FastQC
    reads_for_fastqc = reads_ch
        .flatMap { meta, reads ->
            [
                [meta + [read: 'R1'], reads[0]],
                [meta + [read: 'R2'], reads[1]]
            ]
        }
    
    // Run FastQC on individual read files
    FASTQC(reads_for_fastqc)
    
    // Run STAR alignment
    STAR_ALIGN(
        reads_ch,
        star_index
    )
    
    // Run featureCounts
    FEATURECOUNTS(
        STAR_ALIGN.out.bam,
        annotation_gtf
    )
    
    emit:
    fastqc_html    = FASTQC.out.html
    fastqc_zip     = FASTQC.out.zip
    aligned_bam    = STAR_ALIGN.out.bam
    aligned_bai    = STAR_ALIGN.out.bai
    star_log       = STAR_ALIGN.out.log
    counts         = FEATURECOUNTS.out.counts
    counts_summary = FEATURECOUNTS.out.summary
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    
    main:
    // Create input channel from parameters
    def reads_ch = channel.of([
        [id: params.sample_name],
        [file(params.read1, checkIfExists: true), file(params.read2, checkIfExists: true)]
    ])
    
    // Run the RNA-seq workflow
    RNASEQ(
        reads_ch,
        file(params.star_index, checkIfExists: true),
        file(params.annotation_gtf, checkIfExists: true)
    )
    
    onComplete:
    println "Pipeline completed at: ${workflow.complete}"
    println "Execution status: ${workflow.success ? 'SUCCESS' : 'FAILED'}"
    println "Duration: ${workflow.duration}"
}
