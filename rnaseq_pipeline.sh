#!/bin/bash
#
# RNA-seq Analysis Pipeline (Bash)
# Minimal pipeline: FastQC -> STAR alignment -> featureCounts
#

set -euo pipefail  # Exit on error, undefined variable, or pipe failure

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

RNA-seq Analysis Pipeline

Required Arguments:
    --read1 FILE          Path to R1 FASTQ file (gzipped)
    --read2 FILE          Path to R2 FASTQ file (gzipped)
    --star-index DIR      Path to STAR index directory
    --annotation FILE     Path to GTF annotation file
    --sample-name NAME    Sample identifier

Optional Arguments:
    --output-dir DIR      Output directory (default: results)
    --threads NUM         Number of threads (default: 4)
    --skip-fastqc         Skip FastQC step
    --help                Display this help message

Example:
    $0 \\
        --read1 test_data/reads/sample1_R1.fastq.gz \\
        --read2 test_data/reads/sample1_R2.fastq.gz \\
        --star-index test_data/reference/star_index \\
        --annotation test_data/reference/annotation.gtf \\
        --sample-name sample1 \\
        --output-dir results \\
        --threads 4

EOF
    exit 1
}

# Check if required commands are available
check_dependencies() {
    local missing=0
    local deps=("fastqc" "STAR" "samtools" "featureCounts")

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command not found: $cmd"
            missing=1
        fi
    done

    if [ $missing -eq 1 ]; then
        log_error "Please install missing dependencies"
        exit 1
    fi
}

# Initialize default values
OUTPUT_DIR="results"
THREADS=4
SKIP_FASTQC=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --read1)
            READ1="$2"
            shift 2
            ;;
        --read2)
            READ2="$2"
            shift 2
            ;;
        --star-index)
            STAR_INDEX="$2"
            shift 2
            ;;
        --annotation)
            ANNOTATION="$2"
            shift 2
            ;;
        --sample-name)
            SAMPLE_NAME="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --threads)
            THREADS="$2"
            shift 2
            ;;
        --skip-fastqc)
            SKIP_FASTQC=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [ -z "${READ1:-}" ] || [ -z "${READ2:-}" ] || [ -z "${STAR_INDEX:-}" ] || \
   [ -z "${ANNOTATION:-}" ] || [ -z "${SAMPLE_NAME:-}" ]; then
    log_error "Missing required arguments"
    usage
fi

# Validate input files
if [ ! -f "$READ1" ]; then
    log_error "Read1 file not found: $READ1"
    exit 1
fi

if [ ! -f "$READ2" ]; then
    log_error "Read2 file not found: $READ2"
    exit 1
fi

if [ ! -d "$STAR_INDEX" ]; then
    log_error "STAR index directory not found: $STAR_INDEX"
    exit 1
fi

if [ ! -f "$ANNOTATION" ]; then
    log_error "Annotation file not found: $ANNOTATION"
    exit 1
fi

# Check dependencies
check_dependencies

# Create output directories
mkdir -p "$OUTPUT_DIR"
FASTQC_DIR="$OUTPUT_DIR/fastqc"
STAR_DIR="$OUTPUT_DIR/star"
COUNTS_DIR="$OUTPUT_DIR/counts"

if [ "$SKIP_FASTQC" = false ]; then
    mkdir -p "$FASTQC_DIR"
fi
mkdir -p "$STAR_DIR"
mkdir -p "$COUNTS_DIR"

# Print pipeline information
log_info "============================================================"
log_info "RNA-seq Analysis Pipeline Started"
log_info "============================================================"
log_info "Sample: $SAMPLE_NAME"
log_info "Read1: $READ1"
log_info "Read2: $READ2"
log_info "STAR index: $STAR_INDEX"
log_info "Annotation: $ANNOTATION"
log_info "Output: $OUTPUT_DIR"
log_info "Threads: $THREADS"
log_info "============================================================"

# Step 1: FastQC
if [ "$SKIP_FASTQC" = false ]; then
    log_info "STEP 1: Quality Control with FastQC"

    log_info "Running FastQC on R1..."
    fastqc \
        --outdir "$FASTQC_DIR" \
        --threads 2 \
        "$READ1"

    log_info "Running FastQC on R2..."
    fastqc \
        --outdir "$FASTQC_DIR" \
        --threads 2 \
        "$READ2"

    log_info "FastQC completed"
else
    log_info "STEP 1: Skipping FastQC"
fi

# Step 2: STAR Alignment
log_info "STEP 2: Alignment with STAR"

STAR \
    --runThreadN "$THREADS" \
    --genomeDir "$STAR_INDEX" \
    --readFilesIn "$READ1" "$READ2" \
    --readFilesCommand zcat \
    --outFileNamePrefix "$STAR_DIR/${SAMPLE_NAME}." \
    --outSAMtype BAM SortedByCoordinate \
    --outSAMunmapped Within \
    --outSAMattributes Standard

BAM_FILE="$STAR_DIR/${SAMPLE_NAME}.Aligned.sortedByCoord.out.bam"

log_info "Indexing BAM file..."
samtools index "$BAM_FILE"

log_info "STAR alignment completed"

# Step 3: featureCounts
log_info "STEP 3: Gene quantification with featureCounts"

COUNTS_FILE="$COUNTS_DIR/${SAMPLE_NAME}.counts.txt"

featureCounts \
    -T "$THREADS" \
    -p \
    -t exon \
    -g gene_id \
    -a "$ANNOTATION" \
    -o "$COUNTS_FILE" \
    "$BAM_FILE"

log_info "featureCounts completed"

# Pipeline completion
log_info "============================================================"
log_info "Pipeline completed successfully!"
log_info "Results are in: $OUTPUT_DIR"
log_info "Counts file: $COUNTS_FILE"
log_info "============================================================"

# Print output summary
echo ""
log_info "Output Files:"
if [ "$SKIP_FASTQC" = false ]; then
    echo "  FastQC Reports:"
    ls -lh "$FASTQC_DIR"/*.html 2>/dev/null || true
fi
echo "  Alignment:"
echo "    BAM: $BAM_FILE"
echo "    BAM Index: ${BAM_FILE}.bai"
echo "    STAR Log: $STAR_DIR/${SAMPLE_NAME}.Log.final.out"
echo "  Counts:"
echo "    Counts: $COUNTS_FILE"
echo "    Summary: ${COUNTS_FILE}.summary"
echo ""

log_info "Done!"
