# RNA-seq Pipeline - Nextflow Implementation

This is a Nextflow DSL2 implementation of the RNA-seq analysis pipeline, converted from the Python version.

## Pipeline Overview

This pipeline performs a minimal RNA-seq analysis workflow:

1. **FastQC** - Quality control analysis of raw FASTQ reads (R1 and R2)
2. **STAR** - Alignment of reads to reference genome
3. **featureCounts** - Gene-level read quantification

## Features

- ✅ **Nextflow DSL2** with strict syntax mode for future-proof code
- ✅ **Modular design** with reusable process modules
- ✅ **Wave containers** for reproducible environments
- ✅ **Resource management** with configurable CPU/memory limits
- ✅ **Parameter validation** via JSON schema
- ✅ **Automatic retries** on common failure codes
- ✅ **Version tracking** for all tools used

## Requirements

- Nextflow >= 25.04.0
- Docker or Singularity (containers are pulled automatically)

## Quick Start

### Installation

```bash
# Install Nextflow
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# Or using conda
conda install -c bioconda nextflow
```

### Running the Pipeline

```bash
# Basic usage
nextflow run main.nf \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star_index test_data/reference/star_index \
  --annotation_gtf test_data/reference/annotation.gtf \
  --sample_name sample1 \
  --outdir results

# With custom resources
nextflow run main.nf \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star_index test_data/reference/star_index \
  --annotation_gtf test_data/reference/annotation.gtf \
  --sample_name sample1 \
  --max_cpus 8 \
  --max_memory 16.GB

# Skip FastQC
nextflow run main.nf \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star_index test_data/reference/star_index \
  --annotation_gtf test_data/reference/annotation.gtf \
  --skip_fastqc
```

## Parameters

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `--read1` | Path to R1 FASTQ file (gzipped) |
| `--read2` | Path to R2 FASTQ file (gzipped) |
| `--star_index` | Path to STAR index directory |
| `--annotation_gtf` | Path to GTF annotation file |

### Optional Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--sample_name` | `sample1` | Sample identifier |
| `--outdir` | `results` | Output directory |
| `--skip_fastqc` | `false` | Skip FastQC step |
| `--max_cpus` | `4` | Maximum CPUs to use |
| `--max_memory` | `8.GB` | Maximum memory to use |
| `--max_time` | `6.h` | Maximum time per process |

## Output Structure

```
results/
├── fastqc/
│   ├── sample1_R1_fastqc.html
│   ├── sample1_R1_fastqc.zip
│   ├── sample1_R2_fastqc.html
│   └── sample1_R2_fastqc.zip
├── star/
│   ├── sample1.Aligned.sortedByCoord.out.bam
│   ├── sample1.Aligned.sortedByCoord.out.bam.bai
│   ├── sample1.Log.final.out
│   ├── sample1.Log.out
│   └── sample1.Log.progress.out
└── featurecounts/
    ├── sample1.counts.txt
    └── sample1.counts.txt.summary
```

## Running on Seqera Platform

This pipeline is designed to run seamlessly on Seqera Platform:

```bash
# Using the Seqera CLI or Platform UI
tw launch https://github.com/tylergross97/sample_pipelines_for_conversion \
  --params-file params.yaml \
  --compute-env my-compute-env
```

### Example params.yaml

```yaml
read1: 's3://my-bucket/data/sample1_R1.fastq.gz'
read2: 's3://my-bucket/data/sample1_R2.fastq.gz'
star_index: 's3://my-bucket/reference/star_index'
annotation_gtf: 's3://my-bucket/reference/genes.gtf'
sample_name: 'my_sample'
outdir: 's3://my-bucket/results'
```

## Process Details

### FASTQC

- **Container**: `community.wave.seqera.io/library/fastqc:0.12.1--aa717e1a9d994d74`
- **Resources**: 4 CPUs, 4 GB memory
- **Outputs**: HTML reports and ZIP archives

### STAR_ALIGN

- **Container**: `community.wave.seqera.io/library/samtools_star:86807538d25ae5a9`
- **Resources**: 8 CPUs, 8 GB memory
- **Outputs**: Sorted BAM, BAM index, alignment logs

### FEATURECOUNTS

- **Container**: `community.wave.seqera.io/library/subread:2.0.6--1e9c2492f104316c`
- **Resources**: 4 CPUs, 4 GB memory
- **Outputs**: Gene counts table, summary statistics

## Configuration

The pipeline uses a modular configuration system:

- **nextflow.config** - Main configuration file
- **nextflow_schema.json** - Parameter validation schema
- **modules/** - Process module definitions

### Custom Configuration

Create a custom config file to override defaults:

```groovy
// my_config.config
params {
    max_cpus = 16
    max_memory = '32.GB'
}

process {
    withName: 'STAR_ALIGN' {
        cpus = 12
        memory = '24.GB'
    }
}
```

Run with:
```bash
nextflow run main.nf -c my_config.config --read1 ... --read2 ...
```

## Comparison with Python Version

| Feature | Python | Nextflow |
|---------|--------|----------|
| **Parallelization** | Sequential | Automatic parallelization |
| **Scalability** | Single machine | Cloud-ready, HPC-ready |
| **Resumability** | Manual | Automatic with `-resume` |
| **Containers** | Manual setup | Automatic via Wave |
| **Error handling** | Basic | Retry logic, error strategies |
| **Resource management** | Fixed | Dynamic, configurable |
| **Portability** | Environment-dependent | Container-based |

## Advanced Usage

### Resume Failed Runs

```bash
nextflow run main.nf --read1 ... --read2 ... -resume
```

### Use Custom Profile

```bash
nextflow run main.nf --read1 ... --read2 ... -profile docker
```

### Generate Execution Report

```bash
nextflow run main.nf --read1 ... --read2 ... \
  -with-report report.html \
  -with-timeline timeline.html \
  -with-dag flowchart.html
```

### Run with Singularity

```bash
nextflow run main.nf --read1 ... --read2 ... -profile singularity
```

## Troubleshooting

### Out of Memory Errors

Increase memory allocation:
```bash
nextflow run main.nf --read1 ... --read2 ... --max_memory 16.GB
```

### Missing STAR Index Files

Ensure your STAR index directory contains:
- `Genome`
- `SA`
- `SAindex`
- `chrName.txt`
- `chrLength.txt`

### Container Pull Failures

Pre-pull containers:
```bash
docker pull community.wave.seqera.io/library/fastqc:0.12.1--aa717e1a9d994d74
docker pull community.wave.seqera.io/library/samtools_star:86807538d25ae5a9
docker pull community.wave.seqera.io/library/subread:2.0.6--1e9c2492f104316c
```

## Development

### Module Structure

Each process is defined in its own module:
```
modules/
├── fastqc/
│   └── main.nf
├── star/
│   └── main.nf
└── featurecounts/
    └── main.nf
```

### Adding New Processes

1. Create a new module in `modules/<process_name>/main.nf`
2. Include the module in `main.nf`
3. Add process to the workflow
4. Update configuration if needed

## Citation

If you use this pipeline, please cite:

- **FastQC**: Andrews S. (2010). FastQC: A Quality Control Tool for High Throughput Sequence Data
- **STAR**: Dobin et al. (2013). STAR: ultrafast universal RNA-seq aligner. Bioinformatics 29(1):15-21
- **featureCounts**: Liao et al. (2014). featureCounts: an efficient general purpose program for assigning sequence reads to genomic features. Bioinformatics 30(7):923-30
- **Nextflow**: Di Tommaso et al. (2017). Nextflow enables reproducible computational workflows. Nature Biotechnology 35, 316–319

## License

This pipeline is provided under the MIT License.

## Support

For issues and questions:
- GitHub Issues: https://github.com/tylergross97/sample_pipelines_for_conversion/issues
- Nextflow Documentation: https://www.nextflow.io/docs/latest/
- Seqera Platform: https://seqera.io/
