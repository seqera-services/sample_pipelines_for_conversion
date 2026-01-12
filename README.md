# Sample RNA-seq Pipelines for Conversion

This repository contains sample RNA-seq analysis pipelines implemented in different languages, designed for demonstration purposes with Seqera AI for pipeline conversion to Nextflow.

## Repository Structure

This repository has **six branches**, each containing a minimal RNA-seq pipeline in a different language:

- **`wdl`** - Workflow Description Language (WDL) implementation
- **`r`** - R-based pipeline
- **`python`** - Python-based pipeline
- **`bash`** - Bash shell script pipeline
- **`nextflow`** - Nextflow DSL2 implementation (without unit tests)
- **`snakemake`** - Snakemake workflow implementation

## Pipeline Overview

Each pipeline implements a minimal RNA-seq workflow with three main steps:

1. **Quality Control** - FastQC analysis of raw reads
2. **Alignment** - STAR alignment to reference genome
3. **Quantification** - Feature counting with featureCounts (subread)

## Test Dataset

The pipelines are designed to work with minimal test data for quick demonstrations. We recommend using:

### Option 1: Minimal Test Data (Recommended for Demos)
- **Reads**: Subsampled FASTQ files (10,000 reads)
- **Reference**: Single chromosome or small genome subset
- **Location**: `test_data/` directory (to be created in each branch)

### Option 2: Standard Test Data
- **Reference Genome**: Human chromosome 22 or yeast genome
- **Reads**: Public RNA-seq data from SRA (e.g., SRR1039508 - airway smooth muscle cells)
- Can be downloaded using:
  ```bash
  # Using SRA Toolkit
  fastq-dump --split-files --gzip SRR1039508
  ```

### Data Structure
Each branch will include a `test_data/` directory structure:
```
test_data/
├── reads/
│   ├── sample1_R1.fastq.gz
│   └── sample1_R2.fastq.gz
├── reference/
│   ├── genome.fa
│   └── annotation.gtf
└── README.md (download instructions)
```

## Using This Repository

### For Demonstrations
1. Clone the repository
2. Checkout the branch for the language you want to demonstrate
3. Follow the instructions in that branch's README to:
   - Download/prepare test data
   - Install dependencies
   - Run the pipeline

### For Conversion Practice
Use Seqera AI to convert pipelines from any branch to Nextflow:
1. Checkout a non-Nextflow branch
2. Use Seqera AI to analyze and convert the pipeline
3. Compare with the reference Nextflow implementation

## Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd sample_pipelines_for_conversion

# List all branches
git branch -a

# Checkout a specific pipeline
git checkout wdl        # For WDL pipeline
git checkout python     # For Python pipeline
git checkout snakemake  # For Snakemake pipeline
# etc.
```

## Requirements

Each branch includes its own:
- README with specific installation instructions
- Dependency list (conda environment, Docker container, or manual installation)
- Example run commands
- Expected outputs

## Notes

- All pipelines perform the same analysis steps for consistency
- The Nextflow branch intentionally excludes unit tests to keep it simple for demo purposes
- Each implementation follows best practices for its respective language/framework
- Test data is deliberately minimal to enable quick demo runs (< 5 minutes)

## Contributing

This repository is designed for demonstration purposes. If you'd like to suggest improvements or report issues, please open an issue or pull request.

## License

[Add appropriate license]
