#!/bin/bash
# Quality control and filtering of FASTQ files using fastp

INPUT_DIR="fastq_data"
OUTPUT_DIR="cleaned_fastq"
REPORT_DIR="qc_reports"

mkdir -p $OUTPUT_DIR $REPORT_DIR

echo "Starting quality control with fastp"

for r1 in $INPUT_DIR/*_1.fastq.gz; do
    base_name=$(basename $r1 _1.fastq.gz)
    r2=$INPUT_DIR/${base_name}_2.fastq.gz
    
    echo "Processing sample $base_name"
    
    fastp \
        -i $r1 \
        -I $r2 \
        -o $OUTPUT_DIR/${base_name}_clean_1.fastq.gz \
        -O $OUTPUT_DIR/${base_name}_clean_2.fastq.gz \
        -j $REPORT_DIR/${base_name}.json \
        -h $REPORT_DIR/${base_name}.html \
        -w 10
done

echo "Quality control completed"