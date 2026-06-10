# RNA-seq Analysis Pipeline (Nextflow)

Minimal RNA-seq pipeline converted from a Bash script to Nextflow DSL2.

## Pipeline Steps

1. **FastQC** — Quality control of raw reads
2. **STAR** — Splice-aware alignment to a reference genome
3. **samtools index** — Index aligned BAM files
4. **featureCounts** — Gene-level read quantification

## Quick Start

```bash
nextflow run main.nf \
    --input samplesheet.csv \
    --star_index /path/to/star_index \
    --gtf /path/to/annotation.gtf \
    --outdir results \
    -profile docker
```

## Samplesheet Format

The pipeline requires a CSV samplesheet with the following columns:

| Column   | Description                      |
|----------|----------------------------------|
| sample   | Unique sample identifier         |
| fastq_1  | Path to R1 FASTQ file (gzipped)  |
| fastq_2  | Path to R2 FASTQ file (gzipped)  |

Example:

```csv
sample,fastq_1,fastq_2
sample1,data/sample1_R1.fastq.gz,data/sample1_R2.fastq.gz
sample2,data/sample2_R1.fastq.gz,data/sample2_R2.fastq.gz
```

## Parameters

| Parameter      | Default   | Description                          |
|----------------|-----------|--------------------------------------|
| `--input`      | (required)| Path to samplesheet CSV              |
| `--star_index` | (required)| Path to STAR genome index directory  |
| `--gtf`        | (required)| Path to GTF annotation file          |
| `--outdir`     | `results` | Output directory                     |
| `--skip_fastqc`| `false`   | Skip FastQC step                     |

## Profiles

- `docker` — Run with Docker containers
- `singularity` — Run with Singularity containers
- `wave` — Use Seqera Wave for container provisioning
- `test` — Reduced resource limits for testing

## Output Structure

```
results/
├── fastqc/          # FastQC HTML reports and ZIP archives
├── star/            # Aligned BAM files and STAR logs
│   └── log/         # STAR final log files
└── counts/          # featureCounts output and summaries
```

## Software Versions

| Tool          | Version  |
|---------------|----------|
| FastQC        | 0.12.1   |
| STAR          | 2.7.11b  |
| samtools      | 1.23.1   |
| subread       | 2.1.1    |
