#!/bin/bash
# fastp v0.22.0

fastp \
    -i $input_fastq1 \
    -I $input_fastq2 \
    -o $output_fastq1 \
    -O $output_fastq2 \
    -j $json_report \
    -h $html_report \
    -w 10