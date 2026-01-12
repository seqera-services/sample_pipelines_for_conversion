#!/usr/bin/env python3
"""
RNA-seq Analysis Pipeline
Minimal pipeline: FastQC -> STAR alignment -> featureCounts
"""

import argparse
import subprocess
import sys
from pathlib import Path
import logging


def setup_logging():
    """Configure logging for the pipeline"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    return logging.getLogger(__name__)


def run_command(cmd, description, logger):
    """Execute a shell command and handle errors"""
    logger.info(f"Running: {description}")
    logger.debug(f"Command: {' '.join(cmd)}")

    try:
        result = subprocess.run(
            cmd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        logger.info(f"Completed: {description}")
        return result
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed: {description}")
        logger.error(f"Error: {e.stderr}")
        sys.exit(1)


def fastqc(fastq_file, output_dir, logger):
    """Run FastQC on a FASTQ file"""
    cmd = [
        'fastqc',
        '--outdir', str(output_dir),
        '--threads', '2',
        str(fastq_file)
    ]
    run_command(cmd, f"FastQC on {fastq_file.name}", logger)


def star_align(read1, read2, star_index, sample_name, output_dir, threads, logger):
    """Run STAR alignment"""
    # Create output directory for STAR
    star_output = output_dir / 'star'
    star_output.mkdir(parents=True, exist_ok=True)

    cmd = [
        'STAR',
        '--runThreadN', str(threads),
        '--genomeDir', str(star_index),
        '--readFilesIn', str(read1), str(read2),
        '--readFilesCommand', 'zcat',
        '--outFileNamePrefix', str(star_output / f'{sample_name}.'),
        '--outSAMtype', 'BAM', 'SortedByCoordinate',
        '--outSAMunmapped', 'Within',
        '--outSAMattributes', 'Standard'
    ]
    run_command(cmd, f"STAR alignment for {sample_name}", logger)

    # Index BAM file
    bam_file = star_output / f'{sample_name}.Aligned.sortedByCoord.out.bam'
    cmd_index = ['samtools', 'index', str(bam_file)]
    run_command(cmd_index, f"Indexing BAM file for {sample_name}", logger)

    return bam_file


def feature_counts(bam_file, annotation_gtf, sample_name, output_dir, threads, logger):
    """Run featureCounts for gene quantification"""
    counts_output = output_dir / 'counts'
    counts_output.mkdir(parents=True, exist_ok=True)

    output_file = counts_output / f'{sample_name}.counts.txt'

    cmd = [
        'featureCounts',
        '-T', str(threads),
        '-p',
        '-t', 'exon',
        '-g', 'gene_id',
        '-a', str(annotation_gtf),
        '-o', str(output_file),
        str(bam_file)
    ]
    run_command(cmd, f"featureCounts for {sample_name}", logger)

    return output_file


def main():
    parser = argparse.ArgumentParser(
        description='Minimal RNA-seq analysis pipeline',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example usage:
  python rnaseq_pipeline.py \\
    --read1 test_data/reads/sample1_R1.fastq.gz \\
    --read2 test_data/reads/sample1_R2.fastq.gz \\
    --star-index test_data/reference/star_index \\
    --annotation test_data/reference/annotation.gtf \\
    --sample-name sample1 \\
    --output-dir results \\
    --threads 4
        """
    )

    parser.add_argument('--read1', type=Path, required=True,
                        help='Path to R1 FASTQ file (gzipped)')
    parser.add_argument('--read2', type=Path, required=True,
                        help='Path to R2 FASTQ file (gzipped)')
    parser.add_argument('--star-index', type=Path, required=True,
                        help='Path to STAR index directory')
    parser.add_argument('--annotation', type=Path, required=True,
                        help='Path to GTF annotation file')
    parser.add_argument('--sample-name', type=str, required=True,
                        help='Sample identifier')
    parser.add_argument('--output-dir', type=Path, default='results',
                        help='Output directory (default: results)')
    parser.add_argument('--threads', type=int, default=4,
                        help='Number of threads (default: 4)')
    parser.add_argument('--skip-fastqc', action='store_true',
                        help='Skip FastQC step')

    args = parser.parse_args()

    # Setup logging
    logger = setup_logging()

    # Validate inputs
    if not args.read1.exists():
        logger.error(f"Read1 file not found: {args.read1}")
        sys.exit(1)
    if not args.read2.exists():
        logger.error(f"Read2 file not found: {args.read2}")
        sys.exit(1)
    if not args.star_index.exists():
        logger.error(f"STAR index directory not found: {args.star_index}")
        sys.exit(1)
    if not args.annotation.exists():
        logger.error(f"Annotation file not found: {args.annotation}")
        sys.exit(1)

    # Create output directory
    args.output_dir.mkdir(parents=True, exist_ok=True)

    logger.info("="*60)
    logger.info("RNA-seq Analysis Pipeline Started")
    logger.info("="*60)
    logger.info(f"Sample: {args.sample_name}")
    logger.info(f"Read1: {args.read1}")
    logger.info(f"Read2: {args.read2}")
    logger.info(f"Output: {args.output_dir}")
    logger.info(f"Threads: {args.threads}")
    logger.info("="*60)

    # Step 1: FastQC
    if not args.skip_fastqc:
        logger.info("STEP 1: Quality Control with FastQC")
        fastqc_dir = args.output_dir / 'fastqc'
        fastqc_dir.mkdir(parents=True, exist_ok=True)
        fastqc(args.read1, fastqc_dir, logger)
        fastqc(args.read2, fastqc_dir, logger)
    else:
        logger.info("STEP 1: Skipping FastQC")

    # Step 2: STAR Alignment
    logger.info("STEP 2: Alignment with STAR")
    bam_file = star_align(
        args.read1,
        args.read2,
        args.star_index,
        args.sample_name,
        args.output_dir,
        args.threads,
        logger
    )

    # Step 3: featureCounts
    logger.info("STEP 3: Gene quantification with featureCounts")
    counts_file = feature_counts(
        bam_file,
        args.annotation,
        args.sample_name,
        args.output_dir,
        args.threads,
        logger
    )

    logger.info("="*60)
    logger.info("Pipeline completed successfully!")
    logger.info(f"Results are in: {args.output_dir}")
    logger.info(f"Counts file: {counts_file}")
    logger.info("="*60)


if __name__ == '__main__':
    main()
