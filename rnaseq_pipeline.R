#!/usr/bin/env Rscript
#
# RNA-seq Analysis Pipeline in R
# Minimal pipeline: FastQC -> STAR alignment -> featureCounts
#
# This script orchestrates bioinformatics tools using system() calls
# Similar to how many R-based analysis pipelines work in practice

# Load required packages
suppressPackageStartupMessages({
  if (!require("optparse", quietly = TRUE)) {
    stop("Package 'optparse' is required. Install with: install.packages('optparse')")
  }
})

# Color codes for terminal output
color_red <- "\033[0;31m"
color_green <- "\033[0;32m"
color_yellow <- "\033[1;33m"
color_reset <- "\033[0m"

# Logging functions
log_info <- function(msg) {
  cat(sprintf("%s[INFO]%s %s\n", color_green, color_reset, msg))
}

log_error <- function(msg) {
  cat(sprintf("%s[ERROR]%s %s\n", color_red, color_reset, msg), file = stderr())
}

log_warning <- function(msg) {
  cat(sprintf("%s[WARNING]%s %s\n", color_yellow, color_reset, msg))
}

# Function to run system commands with error checking
run_command <- function(cmd, description) {
  log_info(sprintf("Running: %s", description))

  status <- system(cmd, intern = FALSE)

  if (status != 0) {
    log_error(sprintf("Failed: %s", description))
    log_error(sprintf("Command: %s", cmd))
    quit(status = 1)
  }

  log_info(sprintf("Completed: %s", description))
  return(status)
}

# Function to check if a file exists
check_file <- function(filepath, description) {
  if (!file.exists(filepath)) {
    log_error(sprintf("%s not found: %s", description, filepath))
    quit(status = 1)
  }
}

# Function to check if required tools are installed
check_dependencies <- function() {
  tools <- c("fastqc", "STAR", "samtools", "featureCounts")
  missing <- c()

  for (tool in tools) {
    status <- suppressWarnings(system2("which", tool, stdout = FALSE, stderr = FALSE))
    if (status != 0) {
      missing <- c(missing, tool)
    }
  }

  if (length(missing) > 0) {
    log_error(sprintf("Required tools not found: %s", paste(missing, collapse = ", ")))
    log_error("Please install missing dependencies")
    quit(status = 1)
  }
}

# Define command-line options
option_list <- list(
  make_option(c("--read1"), type = "character", default = NULL,
              help = "Path to R1 FASTQ file (gzipped)", metavar = "FILE"),
  make_option(c("--read2"), type = "character", default = NULL,
              help = "Path to R2 FASTQ file (gzipped)", metavar = "FILE"),
  make_option(c("--star-index"), type = "character", default = NULL,
              help = "Path to STAR index directory", metavar = "DIR"),
  make_option(c("--annotation"), type = "character", default = NULL,
              help = "Path to GTF annotation file", metavar = "FILE"),
  make_option(c("--sample-name"), type = "character", default = NULL,
              help = "Sample identifier", metavar = "NAME"),
  make_option(c("--output-dir"), type = "character", default = "results",
              help = "Output directory [default: %default]", metavar = "DIR"),
  make_option(c("--threads"), type = "integer", default = 4,
              help = "Number of threads [default: %default]", metavar = "NUM"),
  make_option(c("--skip-fastqc"), action = "store_true", default = FALSE,
              help = "Skip FastQC step")
)

# Parse command-line arguments
opt_parser <- OptionParser(
  usage = "%prog [options]",
  option_list = option_list,
  description = "\nRNA-seq Analysis Pipeline in R\n\nMinimal pipeline for processing RNA-seq data with FastQC, STAR, and featureCounts.",
  epilogue = paste(
    "Example:",
    "  Rscript rnaseq_pipeline.R \\",
    "    --read1 test_data/reads/sample1_R1.fastq.gz \\",
    "    --read2 test_data/reads/sample1_R2.fastq.gz \\",
    "    --star-index test_data/reference/star_index \\",
    "    --annotation test_data/reference/annotation.gtf \\",
    "    --sample-name sample1 \\",
    "    --output-dir results \\",
    "    --threads 4",
    sep = "\n"
  )
)

opt <- parse_args(opt_parser)

# Validate required arguments
required_args <- c("read1", "read2", "star-index", "annotation", "sample-name")
missing_args <- required_args[sapply(required_args, function(x) is.null(opt[[x]]))]

if (length(missing_args) > 0) {
  log_error(sprintf("Missing required arguments: %s", paste(missing_args, collapse = ", ")))
  print_help(opt_parser)
  quit(status = 1)
}

# Check dependencies
check_dependencies()

# Validate input files
check_file(opt$read1, "Read1 file")
check_file(opt$read2, "Read2 file")
check_file(opt$`star-index`, "STAR index directory")
check_file(opt$annotation, "Annotation file")

# Create output directories
dir.create(opt$`output-dir`, showWarnings = FALSE, recursive = TRUE)
fastqc_dir <- file.path(opt$`output-dir`, "fastqc")
star_dir <- file.path(opt$`output-dir`, "star")
counts_dir <- file.path(opt$`output-dir`, "counts")

if (!opt$`skip-fastqc`) {
  dir.create(fastqc_dir, showWarnings = FALSE, recursive = TRUE)
}
dir.create(star_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(counts_dir, showWarnings = FALSE, recursive = TRUE)

# Print pipeline information
log_info("============================================================")
log_info("RNA-seq Analysis Pipeline Started")
log_info("============================================================")
log_info(sprintf("Sample: %s", opt$`sample-name`))
log_info(sprintf("Read1: %s", opt$read1))
log_info(sprintf("Read2: %s", opt$read2))
log_info(sprintf("STAR index: %s", opt$`star-index`))
log_info(sprintf("Annotation: %s", opt$annotation))
log_info(sprintf("Output: %s", opt$`output-dir`))
log_info(sprintf("Threads: %d", opt$threads))
log_info("============================================================")

# Step 1: FastQC
if (!opt$`skip-fastqc`) {
  log_info("STEP 1: Quality Control with FastQC")

  # Run FastQC on R1
  cmd_r1 <- sprintf("fastqc --outdir %s --threads 2 %s",
                    shQuote(fastqc_dir), shQuote(opt$read1))
  run_command(cmd_r1, "FastQC on R1")

  # Run FastQC on R2
  cmd_r2 <- sprintf("fastqc --outdir %s --threads 2 %s",
                    shQuote(fastqc_dir), shQuote(opt$read2))
  run_command(cmd_r2, "FastQC on R2")

  log_info("FastQC completed")
} else {
  log_info("STEP 1: Skipping FastQC")
}

# Step 2: STAR Alignment
log_info("STEP 2: Alignment with STAR")

cmd_star <- sprintf(
  paste(
    "STAR",
    "--runThreadN %d",
    "--genomeDir %s",
    "--readFilesIn %s %s",
    "--readFilesCommand zcat",
    "--outFileNamePrefix %s",
    "--outSAMtype BAM SortedByCoordinate",
    "--outSAMunmapped Within",
    "--outSAMattributes Standard"
  ),
  opt$threads,
  shQuote(opt$`star-index`),
  shQuote(opt$read1),
  shQuote(opt$read2),
  shQuote(file.path(star_dir, paste0(opt$`sample-name`, ".")))
)

run_command(cmd_star, sprintf("STAR alignment for %s", opt$`sample-name`))

# Index BAM file
bam_file <- file.path(star_dir, paste0(opt$`sample-name`, ".Aligned.sortedByCoord.out.bam"))
cmd_index <- sprintf("samtools index %s", shQuote(bam_file))
run_command(cmd_index, sprintf("Indexing BAM file for %s", opt$`sample-name`))

log_info("STAR alignment completed")

# Step 3: featureCounts
log_info("STEP 3: Gene quantification with featureCounts")

counts_file <- file.path(counts_dir, paste0(opt$`sample-name`, ".counts.txt"))

cmd_counts <- sprintf(
  paste(
    "featureCounts",
    "-T %d",
    "-p",
    "-t exon",
    "-g gene_id",
    "-a %s",
    "-o %s",
    "%s"
  ),
  opt$threads,
  shQuote(opt$annotation),
  shQuote(counts_file),
  shQuote(bam_file)
)

run_command(cmd_counts, sprintf("featureCounts for %s", opt$`sample-name`))

log_info("featureCounts completed")

# Pipeline completion
log_info("============================================================")
log_info("Pipeline completed successfully!")
log_info(sprintf("Results are in: %s", opt$`output-dir`))
log_info(sprintf("Counts file: %s", counts_file))
log_info("============================================================")

# Print output summary
cat("\n")
log_info("Output Files:")
if (!opt$`skip-fastqc`) {
  cat("  FastQC Reports:\n")
  fastqc_files <- list.files(fastqc_dir, pattern = "\\.html$", full.names = TRUE)
  for (f in fastqc_files) {
    cat(sprintf("    %s\n", f))
  }
}
cat("  Alignment:\n")
cat(sprintf("    BAM: %s\n", bam_file))
cat(sprintf("    BAM Index: %s.bai\n", bam_file))
cat(sprintf("    STAR Log: %s\n",
            file.path(star_dir, paste0(opt$`sample-name`, ".Log.final.out"))))
cat("  Counts:\n")
cat(sprintf("    Counts: %s\n", counts_file))
cat(sprintf("    Summary: %s.summary\n", counts_file))
cat("\n")

log_info("Done!")
