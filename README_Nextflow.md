# RNA-seq Pipeline - Nextflow Implementation

This branch contains a minimal RNA-seq analysis pipeline implemented in Nextflow DSL2, **without unit tests** for simplicity.

## Pipeline Steps

1. **FastQC** - Quality control analysis of raw FASTQ reads (R1 and R2)
2. **STAR** - Alignment of reads to reference genome
3. **samtools index** - Index BAM files
4. **featureCounts** - Gene-level read quantification

## Requirements

- Nextflow 23.04.0 or higher
- One of the following:
  - Docker (recommended)
  - Conda
  - Manual installation of bioinformatics tools

## Installation

### Install Nextflow

```bash
# Quick install
curl -s https://get.nextflow.io | bash

# Or use conda
conda install -c bioconda nextflow

# Or use Homebrew (macOS)
brew install nextflow
```

### Install Dependencies

**Option 1: Docker (Recommended)**
```bash
# Just install Docker - containers will be pulled automatically
docker --version
```

**Option 2: Conda**
```bash
conda install -c bioconda fastqc star samtools subread
```

**Option 3: Manual Installation**
```bash
# See other branch READMEs for manual installation instructions
```

## Test Data Setup

Before running the pipeline, prepare test data:

```bash
mkdir -p test_data/reads
mkdir -p test_data/reference

# Follow instructions in test_data/README.md for downloading test data
```

See the main repository README for detailed instructions on obtaining test datasets.

## Running the Pipeline

### Basic Usage with Docker

```bash
nextflow run main.nf \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star_index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample_name sample1 \
  --outdir results \
  --threads 4 \
  -profile docker
```

### Using Conda

```bash
nextflow run main.nf \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star_index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample_name sample1 \
  -profile conda
```

### Using Local Tools

```bash
nextflow run main.nf \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star_index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample_name sample1
```

### Resume Failed Runs

```bash
# Resume from where the pipeline failed
nextflow run main.nf \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star_index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample_name sample1 \
  -resume
```

## Command-Line Parameters

| Parameter | Required | Description | Default |
|-----------|----------|-------------|---------|
| `--read1` | Yes | Path to R1 FASTQ file (gzipped) | - |
| `--read2` | Yes | Path to R2 FASTQ file (gzipped) | - |
| `--star_index` | Yes | Path to STAR index directory | - |
| `--annotation` | Yes | Path to GTF annotation file | - |
| `--sample_name` | No | Sample identifier | `sample1` |
| `--outdir` | No | Output directory | `results` |
| `--threads` | No | Number of threads | `4` |
| `--skip_fastqc` | No | Skip FastQC step | `false` |

## Output Structure

The pipeline creates the following directory structure:

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
│   └── sample1.Log.final.out
├── counts/
│   ├── sample1.counts.txt
│   └── sample1.counts.txt.summary
├── report.html       # Nextflow execution report
├── timeline.html     # Nextflow timeline
└── trace.txt         # Nextflow trace file
```

### Output Files

#### Quality Control
- `fastqc/*.html` - FastQC HTML reports
- `fastqc/*.zip` - FastQC detailed results

#### Alignment
- `star/*.bam` - Sorted BAM file
- `star/*.bam.bai` - BAM index
- `star/*.Log.final.out` - STAR alignment statistics

#### Quantification
- `counts/*.counts.txt` - Gene counts table
- `counts/*.counts.txt.summary` - featureCounts summary

#### Nextflow Reports
- `report.html` - Execution report with resource usage
- `timeline.html` - Timeline visualization
- `trace.txt` - Process execution trace

## Configuration

The pipeline behavior can be customized via `nextflow.config`:

### Resource Allocation

```groovy
process {
    withName: STAR_ALIGN {
        cpus   = 8
        memory = '64.GB'
        time   = '12.h'
    }
}
```

### Execution Profiles

Available profiles:
- `standard` - Local execution (default)
- `docker` - Use Docker containers
- `conda` - Use Conda environments

### Custom Configuration

Create a custom config file:

```groovy
// custom.config
params {
    outdir = 'my_results'
    threads = 8
}

process {
    withName: STAR_ALIGN {
        memory = '64.GB'
    }
}
```

Run with custom config:
```bash
nextflow run main.nf -c custom.config [other options]
```

## Nextflow Features

This pipeline demonstrates several Nextflow DSL2 features:

- **Processes**: Modular, reusable process definitions
- **Channels**: Data flow management between processes
- **Operators**: Channel manipulation (combine, map, etc.)
- **publishDir**: Organized output publication
- **Profiles**: Different execution environments (docker, conda, local)
- **Config**: Centralized configuration management
- **Resume**: Automatic caching and resume functionality
- **Reports**: Built-in execution reports and visualizations

## Troubleshooting

### Nextflow Not Found

```bash
# Ensure Nextflow is in your PATH
export PATH=$PATH:$(pwd)

# Or install globally
sudo mv nextflow /usr/local/bin/
```

### Docker Permission Denied

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Or run with sudo (not recommended)
sudo nextflow run main.nf [options] -profile docker
```

### Memory Errors

Edit `nextflow.config` to increase memory:
```groovy
process.memory = '64.GB'
```

### Resume Not Working

```bash
# Clean work directory and restart
rm -rf work/
nextflow run main.nf [options]
```

### Check Pipeline Status

```bash
# View detailed logs
cat .nextflow.log

# Check work directory
ls -la work/
```

## Pipeline Design

This Nextflow implementation demonstrates a **simple, straightforward approach**:

- No complex modules or subworkflows (intentionally kept simple for demo)
- No unit tests (as requested)
- Clear process definitions
- Standard channel operations
- Configurable via command-line and config file

This design is typical of how practitioners start with Nextflow before adopting more complex patterns like nf-core modules.

## Next Steps

For production pipelines, consider:
- Adding nf-core modules
- Implementing unit tests with nf-test
- Adding CI/CD validation
- Using nf-core template
- Adding MultiQC for aggregated QC reports
- Implementing sample sheets for batch processing

## Comparing with nf-core

This pipeline is **intentionally simpler** than nf-core pipelines:

| Feature | This Pipeline | nf-core Pipelines |
|---------|---------------|-------------------|
| Modules | Inline processes | External modules |
| Tests | None | Extensive unit tests |
| QC | Basic FastQC | MultiQC aggregation |
| Config | Simple | Highly parameterized |
| Docs | Basic README | Full documentation site |
| CI/CD | Basic Actions | Comprehensive testing |

## Additional Resources

- [Nextflow Documentation](https://www.nextflow.io/docs/latest/)
- [Nextflow Patterns](https://nextflow-io.github.io/patterns/)
- [nf-core](https://nf-co.re/)
- [Nextflow Training](https://training.nextflow.io/)
- [Seqera Platform](https://seqera.io/)
