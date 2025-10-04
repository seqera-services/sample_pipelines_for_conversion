# RNA-seq Pipeline - Nextflow DSL2

This pipeline has been converted from WDL to Nextflow DSL2.

## Pipeline Overview

A minimal RNA-seq analysis pipeline consisting of:

1. **FastQC** - Quality control of raw sequencing reads
2. **STAR** - RNA-seq alignment to reference genome
3. **featureCounts** - Gene-level quantification

## Quick Start

### Prerequisites

- Nextflow >= 24.04.0
- Docker or Singularity

### Running the Pipeline

#### With your own data:

```bash
nextflow run main.nf \
    --read1 /path/to/sample_R1.fastq.gz \
    --read2 /path/to/sample_R2.fastq.gz \
    --sample_name my_sample \
    --star_index /path/to/star_index.tar.gz \
    --annotation_gtf /path/to/genes.gtf \
    --outdir results \
    -profile docker
```

#### With test data:

```bash
nextflow run main.nf -profile test,docker
```

## Parameters

### Required Parameters

- `--read1`: Path to R1 FASTQ file (gzipped)
- `--read2`: Path to R2 FASTQ file (gzipped)
- `--sample_name`: Sample identifier
- `--star_index`: Path to STAR index (tar.gz format)
- `--annotation_gtf`: Path to GTF annotation file

### Optional Parameters

- `--outdir`: Output directory (default: `./results`)
- `--max_cpus`: Maximum CPUs to use (default: 16)
- `--max_memory`: Maximum memory to use (default: 64.GB)
- `--max_time`: Maximum time per task (default: 24.h)

## Profiles

- `docker`: Run with Docker containers
- `singularity`: Run with Singularity containers
- `test`: Run with test dataset (automatically downloads test data)

## Outputs

All outputs are saved to the directory specified by `--outdir`:

```
results/
├── fastqc/
│   ├── *_fastqc.html
│   └── *_fastqc.zip
├── star/
│   ├── *.Aligned.sortedByCoord.out.bam
│   ├── *.Aligned.sortedByCoord.out.bam.bai
│   └── *.Log.final.out
└── featurecounts/
    ├── *.counts.txt
    └── *.counts.txt.summary
```

## WDL to Nextflow Conversion Notes

### Key Differences

1. **Workflow Structure**: 
   - WDL uses `workflow` blocks with explicit task calls
   - Nextflow uses channel-based data flow with modular processes

2. **Input Handling**:
   - WDL: Explicit file inputs per workflow
   - Nextflow: Channel-based inputs with meta maps for sample tracking

3. **Process Definition**:
   - WDL tasks → Nextflow processes
   - WDL `runtime` blocks → Nextflow directives (`container`, `cpus`, `memory`)

4. **Output Publishing**:
   - WDL: Explicit output declarations
   - Nextflow: Outputs flow through channels, can be published via config

### Container Images

All container images are preserved from the original WDL:

- **FastQC**: `biocontainers/fastqc:v0.11.9_cv8`
- **STAR + samtools**: `quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:1df389393721fc66f3fd8778ad938ac711951107-0`
- **featureCounts**: `quay.io/biocontainers/subread:2.0.1--hed695b0_0`

## Pipeline Structure

```
.
├── main.nf                 # Main workflow file
├── nextflow.config         # Configuration and parameters
├── modules/
│   └── local/
│       ├── fastqc.nf       # FastQC process
│       ├── star_align.nf   # STAR alignment process
│       └── featurecounts.nf # featureCounts process
└── NEXTFLOW_README.md      # This file
```

## Credits

Original WDL pipeline converted to Nextflow DSL2 by Seqera AI.

## License

This pipeline is provided as-is for educational and research purposes.
