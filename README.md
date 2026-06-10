# RNA-seq Pipeline (Nextflow DSL2)

A minimal RNA-seq analysis pipeline converted from a Python script to idiomatic Nextflow DSL2.

## Pipeline Steps

1. **FastQC** — Quality control of raw FASTQ reads
2. **STAR** — Spliced alignment to reference genome
3. **samtools index** — Index sorted BAM files
4. **featureCounts** — Gene-level read quantification

## Quick Start

```bash
# Single sample (direct params)
nextflow run main.nf \
    -profile docker \
    --read1 data/sample1_R1.fastq.gz \
    --read2 data/sample1_R2.fastq.gz \
    --star_index references/star_index \
    --gtf references/annotation.gtf \
    --outdir results

# Multiple samples (sample sheet)
nextflow run main.nf \
    -profile docker \
    --input samplesheet.csv \
    --star_index references/star_index \
    --gtf references/annotation.gtf \
    --outdir results
```

## Parameters

| Parameter      | Description                          | Default   |
|---------------|--------------------------------------|-----------|
| `--input`     | Path to sample sheet (CSV)           | null      |
| `--read1`     | Path to R1 FASTQ (single sample)     | null      |
| `--read2`     | Path to R2 FASTQ (single sample)     | null      |
| `--sample_name` | Sample identifier                  | sample1   |
| `--star_index` | STAR genome index directory         | null      |
| `--gtf`       | GTF annotation file                  | null      |
| `--outdir`    | Output directory                     | results   |
| `--skip_fastqc` | Skip FastQC step                   | false     |

## Profiles

- `docker` — Run with Docker containers
- `singularity` — Run with Singularity containers
- `conda` — Run with Conda environments
- `wave` — Run with Seqera Wave containers
- `test` — Run with bundled test data

## Output Structure

```
results/
├── fastqc/          # FastQC reports (HTML + ZIP)
├── star/            # STAR alignments (BAM + BAI + logs)
├── counts/          # featureCounts gene counts
└── pipeline_info/   # Nextflow execution reports
```

## Software Versions

| Tool         | Version  |
|-------------|----------|
| FastQC      | 0.12.1   |
| STAR        | 2.7.11b  |
| samtools    | 1.23.1   |
| subread     | 2.1.1    |

## Requirements

- Nextflow >= 23.04.0
- Docker, Singularity, or Conda
