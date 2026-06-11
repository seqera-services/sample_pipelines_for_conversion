# RNA-seq Pipeline - Nextflow DSL2 Implementation

This pipeline was converted from the WDL implementation on the `wdl` branch.

## Pipeline Steps

1. **FastQC** — Quality control analysis of raw FASTQ reads
2. **STAR GenomeGenerate** — Build STAR index from reference FASTA (optional, skipped if pre-built index provided)
3. **STAR Align** — Align reads to the reference genome
4. **featureCounts** — Gene-level read quantification

## Requirements

- [Nextflow](https://www.nextflow.io/) >= 24.04
- Docker, Singularity, or Conda

## Quick Start

```bash
# Run with the test profile (downloads small test data automatically)
nextflow run main.nf -profile test,docker

# Run with your own data
nextflow run main.nf \
    --input samplesheet.csv \
    --fasta /path/to/genome.fa \
    --gtf /path/to/annotation.gtf \
    -profile docker

# Run with a pre-built STAR index
nextflow run main.nf \
    --input samplesheet.csv \
    --star_index /path/to/star_index \
    --gtf /path/to/annotation.gtf \
    -profile docker
```

## Samplesheet Format

The input samplesheet is a CSV file with the following columns:

| Column   | Description                    |
|----------|--------------------------------|
| sample   | Sample identifier              |
| fastq_1  | Path to R1 FASTQ (gzipped)    |
| fastq_2  | Path to R2 FASTQ (gzipped)    |

Example:
```csv
sample,fastq_1,fastq_2
sample1,/data/reads/sample1_R1.fastq.gz,/data/reads/sample1_R2.fastq.gz
sample2,/data/reads/sample2_R1.fastq.gz,/data/reads/sample2_R2.fastq.gz
```

## Parameters

| Parameter    | Description                           | Default   |
|--------------|---------------------------------------|-----------|
| `--input`    | Path to samplesheet CSV               | (required)|
| `--fasta`    | Reference genome FASTA                | null      |
| `--gtf`      | Annotation GTF file                   | (required)|
| `--star_index` | Pre-built STAR index directory      | null      |
| `--outdir`   | Output directory                      | `results` |

> **Note:** Either `--fasta` or `--star_index` must be provided. If `--star_index` is given, index generation is skipped.

## Output

```
results/
├── fastqc/                    # FastQC HTML reports and ZIP archives
├── star_align/                # Aligned BAM files, BAI indices, STAR logs
├── featurecounts/             # Gene count matrices and summaries
└── pipeline_info/             # Execution timeline, report, trace, DAG
```

## Profiles

| Profile       | Description                              |
|---------------|------------------------------------------|
| `docker`      | Run with Docker containers               |
| `singularity` | Run with Singularity containers          |
| `conda`       | Run with Conda environments              |
| `test`        | Run with minimal test data               |

## Conversion Notes (WDL → Nextflow)

| WDL Concept         | Nextflow Equivalent                        |
|----------------------|--------------------------------------------|
| `task`              | `process`                                   |
| `workflow` inputs   | `params` + samplesheet                      |
| `File` inputs       | Channels with `path` qualifier              |
| `runtime.docker`    | `container` directive                       |
| `runtime.cpu`       | `cpus` via label + config                   |
| `runtime.memory`    | `memory` via label + config                 |
| Single-sample run   | Multi-sample parallelism via samplesheet    |

Key improvements over the WDL version:
- **Parallelism**: Runs all samples concurrently through all steps
- **Resume**: `-resume` flag skips completed tasks on re-run
- **Flexibility**: Supports Docker, Singularity, or Conda
- **Index generation**: Can build STAR index from FASTA or use a pre-built index
