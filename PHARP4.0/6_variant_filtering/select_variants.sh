#!/bin/bash
# Select variants based on specific criteria

INPUT_VCF="filtered.vcf.gz"
OUTPUT_VCF="selected.vcf.gz"
REFERENCE="reference_genome.fa"

echo "Selecting variants"

gatk SelectVariants \
    -R $REFERENCE \
    -V $INPUT_VCF \
    -O $OUTPUT_VCF \
    --select-type-to-include SNP \
    --restrict-alleles-to BIALLELIC \
    --exclude-filtered true \
    --exclude-non-variants true

echo "Variant selection completed