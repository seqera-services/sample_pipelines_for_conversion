# RNA-seq Pipeline - Python Implementation

This branch contains a minimal RNA-seq analysis pipeline implemented in Python.

## Pipeline Steps

1. **FastQC** - Quality control analysis of raw FASTQ reads (R1 and R2)
2. **STAR** - Alignment of reads to reference genome
3. **featureCounts** - Gene-level read quantification

## Requirements

- Python 3.7+
- Bioinformatics tools: FastQC, STAR, samtools, featureCounts
- Optional: PyYAML (for config file support)

## Installation

### Option 1: Using Conda (Recommended)

```bash
# Create conda environment with all dependencies
conda env create -f environment.yml

# Activate environment
conda activate rnaseq-pipeline
```

### Option 2: Manual Installation

Install bioinformatics tools separately:

```bash
# Using conda
conda install -c bioconda fastqc star samtools subread

# Or using package managers
# Ubuntu/Debian
apt-get install fastqc samtools
# Install STAR and subread manually

# macOS
brew install fastqc samtools
# Install STAR and subread manually
```

### Option 3: Using Docker

```bash
# Pull pre-built container with all tools
docker pull quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:1df389393721fc66f3fd8778ad938ac711951107-0
```

## Test Data Setup

Before running the pipeline, prepare test data:

```bash
mkdir -p test_data/reads
mkdir -p test_data/reference

# Follow instructions in test_data/README.md for downloading test data
```

See `test_data/README.md` for detailed instructions on obtaining test datasets.

## Running the Pipeline

### Basic Usage

```bash
# Make script executable
chmod +x rnaseq_pipeline.py

# Run with command-line arguments
./rnaseq_pipeline.py \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --output-dir results \
  --threads 4
```

### Using Python Directly

```bash
python rnaseq_pipeline.py \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --output-dir results \
  --threads 4
```

### Advanced Options

```bash
# Skip FastQC step
./rnaseq_pipeline.py \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --skip-fastqc

# Use more threads
./rnaseq_pipeline.py \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --threads 8

# Custom output directory
./rnaseq_pipeline.py \
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
| `--skip-fastqc` | No | Skip FastQC step | `False` |

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

## Running with Docker

```bash
# Run the entire pipeline in a container
docker run --rm \
  -v $(pwd):/data \
  -w /data \
  quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:1df389393721fc66f3fd8778ad938ac711951107-0 \
  python rnaseq_pipeline.py \
    --read1 test_data/reads/sample1_R1.fastq.gz \
    --read2 test_data/reads/sample1_R2.fastq.gz \
    --star-index test_data/reference/star_index \
    --annotation test_data/reference/annotation.gtf \
    --sample-name sample1
```

## Troubleshooting

### Missing Dependencies

If you get errors about missing commands:

```bash
# Check if tools are installed
which fastqc
which STAR
which samtools
which featureCounts

# Install missing tools via conda
conda install -c bioconda <tool-name>
```

### Permission Errors

```bash
# Make script executable
chmod +x rnaseq_pipeline.py
```

### Memory Issues

If STAR fails with memory errors:
- Reduce number of threads
- Use a smaller reference genome
- Increase system memory allocation

### STAR Index Issues

The STAR index directory should contain these files:
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

- **Logging**: Detailed logging of all steps
- **Error handling**: Graceful error handling with informative messages
- **Validation**: Input file validation before execution
- **Flexibility**: Command-line options for customization
- **Portability**: Works on Linux, macOS, and Windows (with WSL)

## Extending the Pipeline

The Python script is designed to be easily extended:

1. **Add new tools**: Create new functions following the existing pattern
2. **Add QC steps**: Add trimming (e.g., Trimmomatic, cutadapt)
3. **Add visualization**: Generate plots using matplotlib/seaborn
4. **Batch processing**: Modify to process multiple samples
5. **Configuration**: Add YAML config file parsing with PyYAML

Example extension:
```python
def trimmomatic(read1, read2, output_dir, threads, logger):
    """Run Trimmomatic for adapter trimming"""
    # Implementation here
    pass
```

## Converting to Nextflow

This Python pipeline can be analyzed and converted to Nextflow using Seqera AI. The equivalent Nextflow implementation is available on the `nextflow` branch.

## Additional Resources

- [FastQC Documentation](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- [STAR Manual](https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf)
- [featureCounts Documentation](http://subread.sourceforge.net/)
- [Python subprocess Module](https://docs.python.org/3/library/subprocess.html)
