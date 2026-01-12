# RNA-seq Pipeline - Snakemake Implementation

This branch contains a minimal RNA-seq analysis pipeline implemented in Snakemake.

## Pipeline Steps

1. **FastQC** - Quality control analysis of raw FASTQ reads (R1 and R2)
2. **STAR** - Alignment of reads to reference genome
3. **samtools index** - Index BAM files
4. **featureCounts** - Gene-level read quantification

## Requirements

- Snakemake 7.0+
- Python 3.7+
- Bioinformatics tools:
  - FastQC
  - STAR
  - samtools
  - featureCounts (subread package)

## Installation

### Install Snakemake

```bash
# Using conda (recommended)
conda install -c conda-forge -c bioconda snakemake

# Using pip
pip install snakemake

# Using mamba (faster)
mamba install -c conda-forge -c bioconda snakemake
```

### Install Dependencies

**Option 1: Using Conda**
```bash
conda install -c bioconda fastqc star samtools subread
```

**Option 2: Manual Installation**
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

### Basic Usage

```bash
# Run with default config
snakemake --cores 4

# Run with custom cores
snakemake --cores 8

# Dry run (show what would be executed)
snakemake --dry-run

# Print execution plan
snakemake --dry-run --printshellcmds
```

### Using Custom Config

Edit `config.yaml` to customize parameters, then run:

```bash
snakemake --cores 4
```

Or specify a different config file:

```bash
snakemake --configfile custom_config.yaml --cores 4
```

### Override Config via Command Line

```bash
snakemake --cores 4 --config sample_name=mysample threads=8
```

### Generate Reports

```bash
# Run pipeline and create HTML report
snakemake --cores 4 --report report.html

# Create report from existing run
snakemake --report report.html
```

### Visualize DAG

```bash
# Generate DAG visualization
snakemake --dag | dot -Tpng > dag.png

# Generate rule graph
snakemake --rulegraph | dot -Tpng > rulegraph.png
```

## Configuration Options

Edit `config.yaml` to customize the pipeline:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sample_name` | Sample identifier | `sample1` |
| `read1` | Path to R1 FASTQ file | `test_data/reads/sample1_R1.fastq.gz` |
| `read2` | Path to R2 FASTQ file | `test_data/reads/sample1_R2.fastq.gz` |
| `star_index` | Path to STAR index directory | `test_data/reference/star_index` |
| `annotation` | Path to GTF annotation | `test_data/reference/annotation.gtf` |
| `outdir` | Output directory | `results` |
| `threads` | Number of threads | `4` |
| `skip_fastqc` | Skip FastQC step | `false` |

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
│   ├── sample1.Log.final.out
│   ├── sample1.Log.out
│   └── sample1.Log.progress.out
└── counts/
    ├── sample1.counts.txt
    └── sample1.counts.txt.summary

logs/
├── fastqc/
│   ├── sample1_R1.log
│   └── sample1_R2.log
├── star/
│   └── sample1.log
├── samtools/
│   └── sample1.log
└── featurecounts/
    └── sample1.log
```

### Output Files

#### Quality Control
- `results/fastqc/*.html` - FastQC HTML reports
- `results/fastqc/*.zip` - FastQC detailed results

#### Alignment
- `results/star/*.bam` - Sorted BAM file
- `results/star/*.bam.bai` - BAM index
- `results/star/*.Log.final.out` - STAR alignment statistics

#### Quantification
- `results/counts/*.counts.txt` - Gene counts table
- `results/counts/*.counts.txt.summary` - featureCounts summary

#### Logs
- `logs/` - Execution logs for each rule

## Advanced Usage

### Using Conda Environments per Rule

Create an environment file (e.g., `envs/fastqc.yaml`):

```yaml
channels:
  - bioconda
  - conda-forge
dependencies:
  - fastqc=0.11.9
```

Then in Snakefile, add:
```python
rule fastqc:
    conda: "envs/fastqc.yaml"
    ...
```

Run with:
```bash
snakemake --use-conda --cores 4
```

### Cluster Execution

```bash
# SLURM cluster
snakemake --cluster "sbatch -p {cluster.partition} -n {threads}" \\
    --cluster-config cluster.yaml \\
    --cores 100 \\
    --jobs 10

# General cluster
snakemake --cluster "qsub" --cores 100 --jobs 10
```

### Using Profiles

Create a profile in `~/.config/snakemake/my_profile/config.yaml`:

```yaml
cores: 8
use-conda: true
printshellcmds: true
```

Run with:
```bash
snakemake --profile my_profile
```

## Snakemake Features

This pipeline demonstrates several Snakemake features:

- **Rules**: Modular task definitions with inputs, outputs, and commands
- **Config file**: External YAML configuration
- **Wildcards**: Pattern-based file handling
- **Expand**: Generate multiple file targets
- **Threads**: Per-rule thread allocation
- **Logs**: Separate log files for each rule execution
- **Conditional execution**: Skip FastQC based on config
- **DAG visualization**: Automatic workflow graphs

## Troubleshooting

### Snakemake Not Found

```bash
# Install snakemake
conda install -c bioconda snakemake

# Or add to PATH
export PATH=$PATH:~/.local/bin
```

### Missing Input Files

```bash
# Check config.yaml paths
cat config.yaml

# Verify files exist
ls -lh test_data/reads/
ls -lh test_data/reference/
```

### Rule Execution Failed

```bash
# Check logs
cat logs/star/sample1.log

# Re-run failed job
snakemake --cores 4 --rerun-incomplete
```

### Clean Up Failed Run

```bash
# Remove output from failed run
snakemake --delete-all-output

# Or manually
rm -rf results/ logs/ .snakemake/
```

### Force Re-execution

```bash
# Re-run specific rule
snakemake --forcerun star_align --cores 4

# Re-run everything
snakemake --forceall --cores 4
```

## Pipeline Design

This Snakemake implementation demonstrates typical Snakemake patterns:

- **Rule-based workflow** with clear dependencies
- **Config-driven parameters** via YAML
- **Logging** for all rules
- **Thread allocation** per rule
- **Conditional outputs** (skip FastQC)
- **Directory creation** within rules

This is representative of how practitioners write Snakemake workflows in production environments.

## Converting to Nextflow

This Snakemake pipeline can be analyzed and converted to Nextflow using Seqera AI. The equivalent Nextflow implementation is available on the `nextflow` branch.

## Snakemake vs Nextflow

Key differences:

| Feature | Snakemake | Nextflow |
|---------|-----------|----------|
| Paradigm | Pull-based (targets) | Push-based (channels) |
| Language | Python-based | Groovy-based |
| Config | YAML files | Groovy config |
| Parallelization | Automatic DAG | Explicit channels |
| Caching | File-based | Work directory |
| Portability | Conda/containers | Docker/Singularity |

## Additional Resources

- [Snakemake Documentation](https://snakemake.readthedocs.io/)
- [Snakemake Tutorial](https://snakemake.readthedocs.io/en/stable/tutorial/tutorial.html)
- [Snakemake Wrappers](https://snakemake-wrappers.readthedocs.io/)
- [Snakemake Profiles](https://github.com/Snakemake-Profiles)
- [Best Practices](https://snakemake.readthedocs.io/en/stable/snakefiles/best_practices.html)
