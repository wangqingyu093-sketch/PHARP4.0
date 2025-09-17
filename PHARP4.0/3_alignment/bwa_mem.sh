#!/bin/bash
# Alignment of FASTQ files to reference using BWA-MEM and samtools

FASTQ_DIR="cleaned_fastq"
BAM_DIR="aligned_bams"
REFERENCE="./susScr11_genome/susScr11.fa"
THREADS=15

mkdir -p $BAM_DIR

echo "Starting alignment with BWA-MEM"

for r1 in $FASTQ_DIR/*_1.fastq.gz; do
    base_name=$(basename $r1 _clean_1.fastq.gz)
    r2=$FASTQ_DIR/${base_name}_clean_2.fastq.gz
    
    echo "Aligning sample $base_name"
    
    bwa mem -t $THREADS -M $REFERENCE $r1 $r2 | \
    samtools sort -@ $THREADS -O bam -o $BAM_DIR/${base_name}.sorted.bam 
    samtools index $BAM_DIR/${base_name}.sorted.bam
done

echo "Alignment completed"