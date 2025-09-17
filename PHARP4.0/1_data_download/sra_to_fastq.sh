#!/bin/bash
# Convert SRA files to FASTQ format

SRA_DIR="sra_data"
FASTQ_DIR="fastq_data"
THREADS=4

mkdir -p $FASTQ_DIR

echo "Converting SRA files to FASTQ format"

for sra_file in $SRA_DIR/*.sra; do
    base_name=$(basename $sra_file .sra)
    echo "Processing $base_name"
    
    fasterq-dump -e 15 -p -O $FASTQ_DIR --split-3 $sra_file
    for file_fastq in $FASTQ_DIR/*.fastq; do
        bgzip $file_fastq
    done
done


echo "Conversion completed"