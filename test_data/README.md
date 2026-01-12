# Test Data for RNA-seq Pipeline

This directory should contain minimal test data for running the RNA-seq pipeline demonstrations.

## Required Data Structure

```
test_data/
├── reads/
│   ├── sample1_R1.fastq.gz
│   └── sample1_R2.fastq.gz
└── reference/
    ├── star_index/           # STAR index directory
    │   ├── Genome
    │   ├── SA
    │   ├── SAindex
    │   ├── chrName.txt
    │   └── chrLength.txt
    └── annotation.gtf
```

## Quick Test Data Setup (Recommended)

Use subsampled test data from nf-core:

```bash
# Download minimal test data
cd test_data

# Download reads (50k read pairs from S. cerevisiae)
cd reads
wget -q "https://github.com/nf-core/test-datasets/raw/rnaseq/testdata/GSE110004/SRR6357070_1.fastq.gz" -O sample1_R1.fastq.gz
wget -q "https://github.com/nf-core/test-datasets/raw/rnaseq/testdata/GSE110004/SRR6357070_2.fastq.gz" -O sample1_R2.fastq.gz

# Download reference files
cd ../reference
wget -q "https://github.com/nf-core/test-datasets/raw/rnaseq/reference/genome.fa" -O genome.fa
wget -q "https://github.com/nf-core/test-datasets/raw/rnaseq/reference/genes.gtf.gz" -O genes.gtf.gz
gunzip genes.gtf.gz
mv genes.gtf annotation.gtf

# Build STAR index (requires STAR to be installed)
mkdir star_index
STAR --runMode genomeGenerate \
  --genomeDir star_index \
  --genomeFastaFiles genome.fa \
  --sjdbGTFfile annotation.gtf \
  --sjdbOverhang 99 \
  --genomeSAindexNbases 10 \
  --runThreadN 4

# Clean up
rm genome.fa
```

## Expected File Sizes

For demo purposes:
- **Reads**: ~10-20 MB per FASTQ file (gzipped, 50k reads)
- **Reference FASTA**: ~10 MB (S. cerevisiae genome)
- **STAR index**: ~100-200 MB (uncompressed directory)
- **GTF**: ~1-2 MB

## Notes

- The STAR index must be built with `--sjdbOverhang` = (read_length - 1)
- For mixed read lengths, use 100 as a reasonable default
- Ensure read files are gzipped (`.fastq.gz`)
- For R pipeline, STAR index should be a directory, not a tarball
- All paths in command-line arguments should match your actual file locations

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

# Check STAR index directory
ls -lh reference/star_index/
```

## Pre-built Test Data (Alternative)

If you want to skip the setup, you can use pre-built test datasets:

- [nf-core/rnaseq test data](https://github.com/nf-core/test-datasets/tree/rnaseq)
- [Encode project](https://www.encodeproject.org/)
- [10x Genomics datasets](https://www.10xgenomics.com/resources/datasets)
