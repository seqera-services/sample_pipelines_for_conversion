# RNA-seq Pipeline - Bash Implementation

This branch contains a minimal RNA-seq analysis pipeline implemented as a Bash shell script.

## Pipeline Steps

1. **FastQC** - Quality control analysis of raw FASTQ reads (R1 and R2)
2. **STAR** - Alignment of reads to reference genome
3. **featureCounts** - Gene-level read quantification

## Requirements

- Bash 4.0+
- Bioinformatics tools:
  - FastQC
  - STAR
  - samtools
  - featureCounts (subread package)

## Installation

### Option 1: Using Conda (Recommended)

```bash
# Create conda environment
conda create -n rnaseq-bash -c bioconda -c conda-forge \
  fastqc star samtools subread

# Activate environment
conda activate rnaseq-bash
```

### Option 2: Using apt (Ubuntu/Debian)

```bash
# Install from system repositories
sudo apt-get update
sudo apt-get install fastqc samtools

# Install STAR manually
wget https://github.com/alexdobin/STAR/archive/2.7.10b.tar.gz
tar -xzf 2.7.10b.tar.gz
sudo cp STAR-2.7.10b/bin/Linux_x86_64/STAR /usr/local/bin/

# Install subread
wget https://sourceforge.net/projects/subread/files/subread-2.0.3/subread-2.0.3-Linux-x86_64.tar.gz
tar -xzf subread-2.0.3-Linux-x86_64.tar.gz
sudo cp subread-2.0.3-Linux-x86_64/bin/featureCounts /usr/local/bin/
```

### Option 3: Using Homebrew (macOS)

```bash
brew install fastqc samtools
# Install STAR and subread manually as above
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
# Make script executable
chmod +x rnaseq_pipeline.sh

# Run with required arguments
./rnaseq_pipeline.sh \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --output-dir results \
  --threads 4
```

### View Help

```bash
./rnaseq_pipeline.sh --help
```

### Advanced Options

```bash
# Skip FastQC step
./rnaseq_pipeline.sh \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --skip-fastqc

# Use more threads
./rnaseq_pipeline.sh \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --threads 8

# Custom output directory
./rnaseq_pipeline.sh \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --output-dir my_results
```

## Command-Line Options

| Option | Required | Description | Default |
|--------|----------|-------------|---------|
| `--read1` | Yes | Path to R1 FASTQ file (gzipped) | - |
| `--read2` | Yes | Path to R2 FASTQ file (gzipped) | - |
| `--star-index` | Yes | Path to STAR index directory | - |
| `--annotation` | Yes | Path to GTF annotation file | - |
| `--sample-name` | Yes | Sample identifier | - |
| `--output-dir` | No | Output directory | `results` |
| `--threads` | No | Number of threads | `4` |
| `--skip-fastqc` | No | Skip FastQC step | `false` |
| `--help` | No | Display help message | - |

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
```

### Output Files

#### Quality Control
- `fastqc/*.html` - FastQC HTML reports
- `fastqc/*.zip` - FastQC detailed results

#### Alignment
- `star/*.Aligned.sortedByCoord.out.bam` - Sorted BAM file
- `star/*.Aligned.sortedByCoord.out.bam.bai` - BAM index
- `star/*.Log.final.out` - STAR alignment statistics

#### Quantification
- `counts/*.counts.txt` - Gene counts table
- `counts/*.counts.txt.summary` - featureCounts summary

## Script Features

- **Error handling**: Exits immediately on any error (`set -euo pipefail`)
- **Colored output**: Visual feedback with color-coded messages
- **Input validation**: Checks all required files exist before starting
- **Dependency checking**: Verifies all required tools are installed
- **Progress logging**: Detailed logging of each step
- **Output summary**: Lists all generated files at completion

## Troubleshooting

### Missing Dependencies

If you get "command not found" errors:

```bash
# Check if tools are installed
which fastqc
which STAR
which samtools
which featureCounts

# Install missing tools via conda
conda install -c bioconda <tool-name>
```

### Permission Denied

```bash
# Make script executable
chmod +x rnaseq_pipeline.sh
```

### Memory Issues

If STAR fails with memory errors:
- Reduce number of threads
- Use a smaller reference genome
- Increase system memory allocation

### STAR Index Issues

The STAR index directory should contain:
- `Genome`
- `SA`
- `SAindex`
- `chrName.txt`
- `chrLength.txt`

If files are missing, rebuild the index:
```bash
STAR --runMode genomeGenerate \
  --genomeDir star_index \
  --genomeFastaFiles genome.fa \
  --sjdbGTFfile annotation.gtf \
  --sjdbOverhang 99 \
  --runThreadN 4
```

## Pipeline Features

- **Robust error handling**: Script exits on any command failure
- **Input validation**: Pre-flight checks for all input files
- **Colored logging**: Easy-to-read output with color-coded messages
- **Dependency checks**: Verifies required tools before execution
- **Flexible arguments**: Command-line interface with sensible defaults
- **Output summary**: Comprehensive summary at completion

## Example Run

```bash
./rnaseq_pipeline.sh \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name test_sample \
  --output-dir results \
  --threads 4
```

Expected runtime: ~5-15 minutes for minimal test data

## Converting to Nextflow

This Bash pipeline can be analyzed and converted to Nextflow using Seqera AI. The equivalent Nextflow implementation is available on the `nextflow` branch.

## Additional Resources

- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [FastQC Documentation](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- [STAR Manual](https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf)
- [featureCounts Documentation](http://subread.sourceforge.net/)
