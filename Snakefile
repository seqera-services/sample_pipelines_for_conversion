"""
RNA-seq Analysis Pipeline (Snakemake)
Minimal pipeline: FastQC -> STAR alignment -> featureCounts
"""

# Configuration
configfile: "config.yaml"

# Extract parameters
SAMPLE = config["sample_name"]
OUTDIR = config.get("outdir", "results")
SKIP_FASTQC = config.get("skip_fastqc", False)

# Define all final outputs
rule all:
    input:
        # FastQC outputs (conditional)
        [] if SKIP_FASTQC else expand(
            "{outdir}/fastqc/{sample}_{read}_fastqc.html",
            outdir=OUTDIR,
            sample=SAMPLE,
            read=["R1", "R2"]
        ),
        # STAR alignment outputs
        expand("{outdir}/star/{sample}.Aligned.sortedByCoord.out.bam",
               outdir=OUTDIR, sample=SAMPLE),
        expand("{outdir}/star/{sample}.Aligned.sortedByCoord.out.bam.bai",
               outdir=OUTDIR, sample=SAMPLE),
        expand("{outdir}/star/{sample}.Log.final.out",
               outdir=OUTDIR, sample=SAMPLE),
        # featureCounts outputs
        expand("{outdir}/counts/{sample}.counts.txt",
               outdir=OUTDIR, sample=SAMPLE)

# Rule: FastQC on R1
rule fastqc_r1:
    input:
        fastq=config["read1"]
    output:
        html=f"{OUTDIR}/fastqc/{SAMPLE}_R1_fastqc.html",
        zip=f"{OUTDIR}/fastqc/{SAMPLE}_R1_fastqc.zip"
    threads: 2
    log:
        f"logs/fastqc/{SAMPLE}_R1.log"
    shell:
        """
        mkdir -p {OUTDIR}/fastqc
        fastqc \\
            --threads {threads} \\
            --quiet \\
            --outdir {OUTDIR}/fastqc \\
            {input.fastq} \\
            2> {log}
        """

# Rule: FastQC on R2
rule fastqc_r2:
    input:
        fastq=config["read2"]
    output:
        html=f"{OUTDIR}/fastqc/{SAMPLE}_R2_fastqc.html",
        zip=f"{OUTDIR}/fastqc/{SAMPLE}_R2_fastqc.zip"
    threads: 2
    log:
        f"logs/fastqc/{SAMPLE}_R2.log"
    shell:
        """
        mkdir -p {OUTDIR}/fastqc
        fastqc \\
            --threads {threads} \\
            --quiet \\
            --outdir {OUTDIR}/fastqc \\
            {input.fastq} \\
            2> {log}
        """

# Rule: STAR alignment
rule star_align:
    input:
        read1=config["read1"],
        read2=config["read2"],
        index=directory(config["star_index"])
    output:
        bam=f"{OUTDIR}/star/{SAMPLE}.Aligned.sortedByCoord.out.bam",
        log_final=f"{OUTDIR}/star/{SAMPLE}.Log.final.out",
        log_out=f"{OUTDIR}/star/{SAMPLE}.Log.out",
        log_progress=f"{OUTDIR}/star/{SAMPLE}.Log.progress.out"
    params:
        prefix=f"{OUTDIR}/star/{SAMPLE}."
    threads: config.get("threads", 4)
    log:
        f"logs/star/{SAMPLE}.log"
    shell:
        """
        mkdir -p {OUTDIR}/star
        STAR \\
            --runThreadN {threads} \\
            --genomeDir {input.index} \\
            --readFilesIn {input.read1} {input.read2} \\
            --readFilesCommand zcat \\
            --outFileNamePrefix {params.prefix} \\
            --outSAMtype BAM SortedByCoordinate \\
            --outSAMunmapped Within \\
            --outSAMattributes Standard \\
            2> {log}
        """

# Rule: Index BAM file
rule samtools_index:
    input:
        bam=f"{OUTDIR}/star/{SAMPLE}.Aligned.sortedByCoord.out.bam"
    output:
        bai=f"{OUTDIR}/star/{SAMPLE}.Aligned.sortedByCoord.out.bam.bai"
    threads: 1
    log:
        f"logs/samtools/{SAMPLE}.log"
    shell:
        """
        samtools index {input.bam} 2> {log}
        """

# Rule: featureCounts quantification
rule featurecounts:
    input:
        bam=f"{OUTDIR}/star/{SAMPLE}.Aligned.sortedByCoord.out.bam",
        bai=f"{OUTDIR}/star/{SAMPLE}.Aligned.sortedByCoord.out.bam.bai",
        annotation=config["annotation"]
    output:
        counts=f"{OUTDIR}/counts/{SAMPLE}.counts.txt",
        summary=f"{OUTDIR}/counts/{SAMPLE}.counts.txt.summary"
    threads: config.get("threads", 4)
    log:
        f"logs/featurecounts/{SAMPLE}.log"
    shell:
        """
        mkdir -p {OUTDIR}/counts
        featureCounts \\
            -T {threads} \\
            -p \\
            -t exon \\
            -g gene_id \\
            -a {input.annotation} \\
            -o {output.counts} \\
            {input.bam} \\
            2> {log}
        """
