version 1.0

## RNA-seq Pipeline in WDL
## Minimal pipeline: FastQC -> STAR alignment -> featureCounts

workflow RNAseq {
  input {
    File read1
    File read2
    String sample_name
    File star_index_tar
    File annotation_gtf
    Int threads = 4
    String memory = "8G"
  }

  call FastQC as FastQC_R1 {
    input:
      fastq = read1,
      sample_name = sample_name + "_R1"
  }

  call FastQC as FastQC_R2 {
    input:
      fastq = read2,
      sample_name = sample_name + "_R2"
  }

  call STARAlign {
    input:
      read1 = read1,
      read2 = read2,
      sample_name = sample_name,
      star_index_tar = star_index_tar,
      threads = threads,
      memory = memory
  }

  call FeatureCounts {
    input:
      bam = STARAlign.aligned_bam,
      annotation_gtf = annotation_gtf,
      sample_name = sample_name,
      threads = threads
  }

  output {
    File fastqc_r1_html = FastQC_R1.html_report
    File fastqc_r1_zip = FastQC_R1.zip_report
    File fastqc_r2_html = FastQC_R2.html_report
    File fastqc_r2_zip = FastQC_R2.zip_report
    File aligned_bam = STARAlign.aligned_bam
    File aligned_bai = STARAlign.aligned_bai
    File star_log = STARAlign.log_final
    File counts = FeatureCounts.counts
    File counts_summary = FeatureCounts.summary
  }
}

task FastQC {
  input {
    File fastq
    String sample_name
  }

  command <<<
    fastqc \
      --outdir . \
      --threads 2 \
      ~{fastq}
  >>>

  output {
    File html_report = glob("*_fastqc.html")[0]
    File zip_report = glob("*_fastqc.zip")[0]
  }

  runtime {
    docker: "biocontainers/fastqc:v0.11.9_cv8"
    cpu: 2
    memory: "2G"
  }
}

task STARAlign {
  input {
    File read1
    File read2
    String sample_name
    File star_index_tar
    Int threads
    String memory
  }

  command <<<
    set -e

    # Extract STAR index
    mkdir -p star_index
    tar -xzf ~{star_index_tar} -C star_index --strip-components=1

    # Run STAR alignment
    STAR \
      --runThreadN ~{threads} \
      --genomeDir star_index \
      --readFilesIn ~{read1} ~{read2} \
      --readFilesCommand zcat \
      --outFileNamePrefix ~{sample_name}. \
      --outSAMtype BAM SortedByCoordinate \
      --outSAMunmapped Within \
      --outSAMattributes Standard

    # Index BAM file
    samtools index ~{sample_name}.Aligned.sortedByCoord.out.bam
  >>>

  output {
    File aligned_bam = "~{sample_name}.Aligned.sortedByCoord.out.bam"
    File aligned_bai = "~{sample_name}.Aligned.sortedByCoord.out.bam.bai"
    File log_final = "~{sample_name}.Log.final.out"
  }

  runtime {
    docker: "quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:1df389393721fc66f3fd8778ad938ac711951107-0"
    cpu: threads
    memory: memory
  }
}

task FeatureCounts {
  input {
    File bam
    File annotation_gtf
    String sample_name
    Int threads
  }

  command <<<
    featureCounts \
      -T ~{threads} \
      -p \
      -t exon \
      -g gene_id \
      -a ~{annotation_gtf} \
      -o ~{sample_name}.counts.txt \
      ~{bam}
  >>>

  output {
    File counts = "~{sample_name}.counts.txt"
    File summary = "~{sample_name}.counts.txt.summary"
  }

  runtime {
    docker: "quay.io/biocontainers/subread:2.0.1--hed695b0_0"
    cpu: threads
    memory: "4G"
  }
}
