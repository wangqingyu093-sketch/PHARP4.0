#!/bin/bash
# Phasing of variants using Beagle

INPUT_VCF="selected.vcf.gz"
OUTPUT_VCF="phased.vcf.gz"
THREADS=8
MEMORY="32G"

echo "Phasing variants with Beagle"

java -Xmx$MEMORY -jar beagle.jar \
    gt=$INPUT_VCF \
    out=$OUTPUT_VCF \
    nthreads=$THREADS

echo "Phasing completed"