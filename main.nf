#!/usr/bin/env nextflow
/*
========================================================================================
    RNA-seq Analysis Pipeline
========================================================================================
    Minimal pipeline: FastQC -> STAR alignment -> featureCounts
    Converted from Python implementation to Nextflow DSL2
----------------------------------------------------------------------------------------
*/

nextflow.enable.strict = true

/*
========================================================================================
    PARAMETER VALIDATION
========================================================================================
*/

// Validate required parameters
if (!params.read1) {
    error "Error: --read1 parameter is required"
}
if (!params.read2) {
    error "Error: --read2 parameter is required"
}
if (!params.star_index) {
    error "Error: --star_index parameter is required"
}
if (!params.annotation_gtf) {
    error "Error: --annotation_gtf parameter is required"
}

/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { FASTQC        } from './modules/fastqc/main.nf'
include { STAR_ALIGN    } from './modules/star/main.nf'
include { FEATURECOUNTS } from './modules/featurecounts/main.nf'

/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow {
    
    main:
    //
    // Create input channel
    //
    def meta = [id: params.sample_name, single_end: false]
    def ch_reads = channel.of([meta, [file(params.read1), file(params.read2)]])
    
    //
    // STEP 1: Quality Control with FastQC
    //
    def ch_fastqc_html = channel.empty()
    def ch_fastqc_zip = channel.empty()
    
    if (!params.skip_fastqc) {
        FASTQC(ch_reads)
        ch_fastqc_html = FASTQC.out.html
        ch_fastqc_zip = FASTQC.out.zip
    }
    
    //
    // STEP 2: Alignment with STAR
    //
    def ch_star_index = channel.fromPath(params.star_index, type: 'dir', checkIfExists: true)
    
    STAR_ALIGN(
        ch_reads,
        ch_star_index
    )
    
    //
    // STEP 3: Gene quantification with featureCounts
    //
    def ch_gtf = channel.fromPath(params.annotation_gtf, checkIfExists: true)
    
    FEATURECOUNTS(
        STAR_ALIGN.out.bam,
        ch_gtf
    )
    
    onComplete:
    println "Pipeline completed at: ${workflow.complete}"
    println "Status: ${workflow.success ? 'SUCCESS' : 'FAILED'}"
    
    onError:
    println "Pipeline failed: ${workflow.errorMessage}"
}

/*
========================================================================================
    WORKFLOW OUTPUTS
========================================================================================
*/

output {
    directory params.outdir
    mode 'copy'
}
