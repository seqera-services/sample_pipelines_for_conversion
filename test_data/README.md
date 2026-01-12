# Test Data for RNA-seq Pipeline

This directory should contain minimal test data for running the RNA-seq pipeline demonstrations.

## Required Data Structure

```
test_data/
├── reads/
│   ├── sample1_R1.fastq.gz
│   └── sample1_R2.fastq.gz
└── reference/
    ├── star_index.tar.gz
    └── annotation.gtf
```

## Option 1: Quick Test Data (Recommended for Demos)

Use subsampled test data from nf-core:

```bash
# Download minimal test data
cd test_data

# Download reads (10k read pairs, human chr 22)
wget -O reads/sample1_R1.fastq.gz https://raw.githubusercontent.com/nf-core/test-datasets/rnaseq/testdata/SRR4238351_subsamp_1.fastq.gz
wget -O reads/sample1_R2.fastq.gz https://raw.githubusercontent.com/nf-core/test-datasets/rnaseq/testdata/SRR4238351_subsamp_2.fastq.gz

# Download reference files
cd reference
wget https://raw.githubusercontent.com/nf-core/test-datasets/rnaseq/reference/genes.gtf.gz
gunzip genes.gtf.gz
mv genes.gtf annotation.gtf

# Download genome for STAR index
wget https://raw.githubusercontent.com/nf-core/test-datasets/rnaseq/reference/genome.fa

# Build STAR index (requires STAR to be installed)
mkdir star_index_temp
STAR --runMode genomeGenerate \
  --genomeDir star_index_temp \
  --genomeFastaFiles genome.fa \
  --sjdbGTFfile annotation.gtf \
  --sjdbOverhang 99 \
  --genomeSAindexNbases 10 \
  --runThreadN 4

# Package the index
tar -czf star_index.tar.gz -C star_index_temp .
rm -rf star_index_temp genome.fa
```

## Option 2: Standard Test Data

Use standard Ensembl reference data:

```bash
cd test_data/reference

# Download human reference (chromosome 22 only)
wget http://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.chromosome.22.fa.gz
gunzip Homo_sapiens.GRCh38.dna.chromosome.22.fa.gz
mv Homo_sapiens.GRCh38.dna.chromosome.22.fa genome.fa

# Download GTF annotation
wget http://ftp.ensembl.org/pub/release-110/gtf/homo_sapiens/Homo_sapiens.GRCh38.110.gtf.gz
gunzip Homo_sapiens.GRCh38.110.gtf.gz
mv Homo_sapiens.GRCh38.110.gtf annotation.gtf

# Build STAR index for chromosome 22
mkdir star_index_temp
STAR --runMode genomeGenerate \
  --genomeDir star_index_temp \
  --genomeFastaFiles genome.fa \
  --sjdbGTFfile annotation.gtf \
  --sjdbOverhang 99 \
  --genomeSAindexNbases 11 \
  --runThreadN 4

tar -czf star_index.tar.gz -C star_index_temp .
rm -rf star_index_temp
```

For reads, download from SRA:
```bash
cd test_data/reads

# Download a small RNA-seq sample
fastq-dump --split-files --gzip SRR1039508

# Subsample to 10k reads for faster testing
seqtk sample -s100 SRR1039508_1.fastq.gz 10000 | gzip > sample1_R1.fastq.gz
seqtk sample -s100 SRR1039508_2.fastq.gz 10000 | gzip > sample1_R2.fastq.gz

# Clean up
rm SRR1039508_*.fastq.gz
```

## Option 3: Docker-based Setup

Use a Docker container with pre-installed tools:

```bash
docker run --rm -v $(pwd):/data -w /data \
  quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:1df389393721fc66f3fd8778ad938ac711951107-0 \
  bash -c "your download commands here"
```

## Expected File Sizes

For demo purposes, aim for:
- **Reads**: ~5-10 MB per FASTQ file (gzipped)
- **Reference FASTA**: ~10-50 MB (single chromosome or small genome)
- **STAR index**: ~500 MB - 2 GB (compressed)
- **GTF**: ~5-50 MB

## Notes

- The STAR index must be built with `--sjdbOverhang` = (read_length - 1)
- For mixed read lengths, use 100 as a reasonable default
- Ensure read files are gzipped (`.fastq.gz`)
- All paths in `inputs.json` should match your actual file locations

## Quick Validation

After downloading, verify your setup:

```bash
# Check files exist
ls -lh reads/
ls -lh reference/

# Verify FASTQ format
zcat reads/sample1_R1.fastq.gz | head -4

# Verify GTF format
head reference/annotation.gtf

# Check STAR index contents
tar -tzf reference/star_index.tar.gz | head
```

## Pre-built Test Data (Alternative)

If you want to skip the setup, you can use pre-built test datasets:

- [nf-core/rnaseq test data](https://github.com/nf-core/test-datasets/tree/rnaseq)
- [Encode project](https://www.encodeproject.org/)
- [10x Genomics datasets](https://www.10xgenomics.com/resources/datasets)
