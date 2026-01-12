# RNA-seq Pipeline - WDL Implementation

This branch contains a minimal RNA-seq analysis pipeline implemented in Workflow Description Language (WDL).

## Pipeline Steps

1. **FastQC** - Quality control analysis of raw FASTQ reads (R1 and R2)
2. **STAR** - Alignment of reads to reference genome
3. **featureCounts** - Gene-level read quantification

## Requirements

### Option 1: Cromwell + Docker (Recommended)
- [Cromwell](https://github.com/broadinstitute/cromwell) (WDL execution engine)
- Docker
- Java 11+

### Option 2: miniWDL
- [miniWDL](https://github.com/chanzuckerberg/miniwdl) (`pip install miniwdl`)
- Docker

## Installation

### Install Cromwell
```bash
# Download Cromwell JAR
wget https://github.com/broadinstitute/cromwell/releases/download/85/cromwell-85.jar

# Or use conda
conda install -c bioconda cromwell
```

### Install miniWDL
```bash
pip install miniwdl
```

## Test Data Setup

Before running the pipeline, you need to prepare test data:

1. Create the test data directory structure:
```bash
mkdir -p test_data/reads
mkdir -p test_data/reference
```

2. Download or create minimal test data:

**Option A: Use provided script (recommended)**
```bash
# See test_data/README.md for download instructions
cd test_data
./download_test_data.sh
```

**Option B: Use your own data**
- Place paired-end FASTQ files in `test_data/reads/`
- Place STAR index (tar.gz) in `test_data/reference/`
- Place GTF annotation in `test_data/reference/`

## Running the Pipeline

### Using Cromwell
```bash
# Run with default inputs
java -jar cromwell-85.jar run rnaseq.wdl -i inputs.json

# Run with custom inputs
java -jar cromwell-85.jar run rnaseq.wdl -i my_inputs.json

# Run with options file (for additional configuration)
java -jar cromwell-85.jar run rnaseq.wdl -i inputs.json -o cromwell.options
```

### Using miniWDL
```bash
# Run with default inputs
miniwdl run rnaseq.wdl -i inputs.json

# Run with custom inputs
miniwdl run rnaseq.wdl -i my_inputs.json

# Check workflow
miniwdl check rnaseq.wdl
```

## Input Parameters

Edit `inputs.json` to customize the pipeline:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `read1` | Path to R1 FASTQ file | `test_data/reads/sample1_R1.fastq.gz` |
| `read2` | Path to R2 FASTQ file | `test_data/reads/sample1_R2.fastq.gz` |
| `sample_name` | Sample identifier | `sample1` |
| `star_index_tar` | STAR index tarball | `test_data/reference/star_index.tar.gz` |
| `annotation_gtf` | GTF annotation file | `test_data/reference/annotation.gtf` |
| `threads` | Number of threads | `4` |
| `memory` | Memory allocation | `8G` |

## Output Files

The pipeline generates the following outputs:

### Quality Control
- `*_fastqc.html` - FastQC HTML reports (R1 and R2)
- `*_fastqc.zip` - FastQC detailed results

### Alignment
- `*.Aligned.sortedByCoord.out.bam` - Sorted BAM file
- `*.Aligned.sortedByCoord.out.bam.bai` - BAM index
- `*.Log.final.out` - STAR alignment statistics

### Quantification
- `*.counts.txt` - Gene counts table
- `*.counts.txt.summary` - featureCounts summary statistics

## Workflow Structure

```
RNAseq (workflow)
├── FastQC_R1 (task)
├── FastQC_R2 (task)
├── STARAlign (task)
└── FeatureCounts (task)
```

## Docker Containers

The pipeline uses official Biocontainers images:
- **FastQC**: `biocontainers/fastqc:v0.11.9_cv8`
- **STAR + samtools**: `quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2`
- **featureCounts**: `quay.io/biocontainers/subread:2.0.1--hed695b0_0`

## Troubleshooting

### Docker Issues
If you encounter Docker-related errors:
```bash
# Ensure Docker is running
docker ps

# Pull containers manually
docker pull biocontainers/fastqc:v0.11.9_cv8
docker pull quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:1df389393721fc66f3fd8778ad938ac711951107-0
docker pull quay.io/biocontainers/subread:2.0.1--hed695b0_0
```

### Memory Issues
If tasks fail due to memory:
- Increase memory in `inputs.json`
- Reduce threads to lower memory footprint
- Check available system resources

### STAR Index
The STAR index must match your FASTQ read length:
- For short reads (50-75bp): Use appropriate overhang
- For longer reads (100-150bp): Standard index works

## Converting to Nextflow

This WDL pipeline can be analyzed and converted to Nextflow using Seqera AI. The equivalent Nextflow implementation is available on the `nextflow` branch.

## Additional Resources

- [WDL Specification](https://github.com/openwdl/wdl/blob/main/versions/1.0/SPEC.md)
- [Cromwell Documentation](https://cromwell.readthedocs.io/)
- [miniWDL Documentation](https://miniwdl.readthedocs.io/)
- [STAR Manual](https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf)
