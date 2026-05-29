#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RNA-seq Analysis Pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Converted from: rnaseq_pipeline.py
    Pipeline steps: FastQC → STAR Alignment → featureCounts
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC        } from './modules/local/fastqc'
include { STAR_ALIGN    } from './modules/local/star_align'
include { FEATURECOUNTS } from './modules/local/featurecounts'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def getResourceTier(file_size_bytes) {
    // Determine resource tier based on total FASTQ file size
    // Small: < 1 GB, Medium: 1-5 GB, Large: > 5 GB
    def size_gb = file_size_bytes / 1_000_000_000
    if (size_gb < 1) {
        return 'small'
    } else if (size_gb < 5) {
        return 'medium'
    } else {
        return 'large'
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    // ----------------------------
    // Validate required parameters
    // ----------------------------
    if (!params.input) {
        error "ERROR: 'input' parameter is required. Provide a samplesheet CSV."
    }
    if (!params.star_index) {
        error "ERROR: 'star_index' parameter is required. Provide a path to the STAR index directory."
    }
    if (!params.annotation) {
        error "ERROR: 'annotation' parameter is required. Provide a GTF annotation file."
    }

    // ----------------------------
    // Input channels
    // ----------------------------

    // Parse samplesheet: sample_id, fastq_1, fastq_2, single_end
    ch_reads = channel.fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            def meta = [
                id:         row.sample_id,
                single_end: row.containsKey('fastq_2') ? (row.fastq_2 ? false : true) : true
            ]
            def reads = meta.single_end
                ? [ file(row.fastq_1, checkIfExists: true) ]
                : [ file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true) ]

            // Calculate total file size for dynamic resource allocation
            def total_size = reads.collect { f -> f.size() }.sum()
            meta.size_tier = getResourceTier(total_size)

            return [ meta, reads ]
        }

    ch_star_index  = channel.fromPath(params.star_index, checkIfExists: true).collect()
    ch_annotation  = channel.fromPath(params.annotation, checkIfExists: true).collect()

    // ----------------------------
    // STEP 1: Quality Control
    // ----------------------------
    if (!params.skip_fastqc) {
        FASTQC(ch_reads)
    }

    // ----------------------------
    // STEP 2: STAR Alignment
    // ----------------------------
    STAR_ALIGN(ch_reads, ch_star_index)

    // ----------------------------
    // STEP 3: Gene Quantification
    // ----------------------------
    // Join BAM with BAI for featureCounts input
    ch_bam_bai = STAR_ALIGN.out.bam
        .join(STAR_ALIGN.out.bai)
        .map { meta, bam, bai -> [ meta, bam, bai ] }

    FEATURECOUNTS(ch_bam_bai, ch_annotation)

    // ----------------------------
    // Collect software versions
    // ----------------------------
    ch_versions = channel.empty()
    if (!params.skip_fastqc) {
        ch_versions = ch_versions.mix(FASTQC.out.versions.first())
    }
    ch_versions = ch_versions
        .mix(STAR_ALIGN.out.versions.first())
        .mix(FEATURECOUNTS.out.versions.first())

    ch_versions.collectFile(name: 'software_versions.yml', storeDir: "${params.outdir}/pipeline_info")
}
