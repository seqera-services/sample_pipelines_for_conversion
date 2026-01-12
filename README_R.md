# RNA-seq Pipeline - R Implementation

This branch contains a minimal RNA-seq analysis pipeline implemented in R using Rscript.

## Pipeline Steps

1. **FastQC** - Quality control analysis of raw FASTQ reads (R1 and R2)
2. **STAR** - Alignment of reads to reference genome
3. **featureCounts** - Gene-level read quantification

## Requirements

- R 4.0+
- R package: `optparse` (for command-line argument parsing)
- Bioinformatics tools:
  - FastQC
  - STAR
  - samtools
  - featureCounts (subread package)

## Installation

### Install R and Dependencies

#### Option 1: Using Conda (Recommended)

```bash
# Create conda environment
conda create -n rnaseq-r -c conda-forge -c bioconda \
  r-base=4.2 \
  r-optparse \
  fastqc \
  star \
  samtools \
  subread

# Activate environment
conda activate rnaseq-r
```

#### Option 2: System Installation

**Install R:**
```bash
# Ubuntu/Debian
sudo apt-get install r-base

# macOS
brew install r
```

**Install R packages:**
```R
# In R console
install.packages("optparse")
```

**Install bioinformatics tools:**
```bash
# Using apt (Ubuntu/Debian)
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
# Make script executable (optional, can use Rscript directly)
chmod +x rnaseq_pipeline.R

# Run with Rscript
Rscript rnaseq_pipeline.R \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --output-dir results \
  --threads 4

# Or if executable
./rnaseq_pipeline.R \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1
```

### View Help

```bash
Rscript rnaseq_pipeline.R --help
```

### Advanced Options

```bash
# Skip FastQC step
Rscript rnaseq_pipeline.R \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --skip-fastqc

# Use more threads
Rscript rnaseq_pipeline.R \
  --read1 test_data/reads/sample1_R1.fastq.gz \
  --read2 test_data/reads/sample1_R2.fastq.gz \
  --star-index test_data/reference/star_index \
  --annotation test_data/reference/annotation.gtf \
  --sample-name sample1 \
  --threads 8

# Custom output directory
Rscript rnaseq_pipeline.R \
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
| `--skip-fastqc` | No | Skip FastQC step | `FALSE` |
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

- **R idioms**: Uses proper R conventions and style
- **optparse package**: Professional command-line argument parsing
- **Error handling**: Validates inputs and checks command exit status
- **Colored output**: Visual feedback with color-coded messages
- **Input validation**: Checks all required files exist before starting
- **Dependency checking**: Verifies all required tools are installed
- **Progress logging**: Detailed logging of each step
- **Output summary**: Lists all generated files at completion

## Troubleshooting

### Missing R Package

If you get "package 'optparse' is required" error:

```R
# In R console
install.packages("optparse")
```

Or with conda:
```bash
conda install -c conda-forge r-optparse
```

### Missing Bioinformatics Tools

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
chmod +x rnaseq_pipeline.R
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

## Why R for RNA-seq Pipelines?

While R is traditionally used for downstream analysis (DESeq2, edgeR, etc.), this pipeline demonstrates a common pattern in bioinformatics where:

1. **R orchestrates external tools** via `system()` calls
2. **Command-line interface** is provided via `optparse`
3. **Integration** with downstream R analysis is seamless
4. **Reproducibility** is maintained within an R environment

In practice, many bioinformatics labs use R scripts to:
- Wrap external tools in a unified interface
- Integrate preprocessing with statistical analysis
- Maintain all analysis code in a single language
- Leverage R's extensive bioinformatics ecosystem

## Next Steps

After running this pipeline, you can import the counts data into R for downstream analysis:

```R
# Read counts data
counts <- read.table("results/counts/sample1.counts.txt",
                     header = TRUE,
                     row.names = 1,
                     skip = 1)

# Remove metadata columns
counts <- counts[, 6:ncol(counts)]

# Continue with DESeq2, edgeR, or other analysis packages
```

## Converting to Nextflow

This R pipeline can be analyzed and converted to Nextflow using Seqera AI. The equivalent Nextflow implementation is available on the `nextflow` branch.

## Additional Resources

- [R for Bioinformatics](https://www.bioconductor.org/)
- [optparse package documentation](https://cran.r-project.org/web/packages/optparse/)
- [FastQC Documentation](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- [STAR Manual](https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf)
- [featureCounts Documentation](http://subread.sourceforge.net/)
