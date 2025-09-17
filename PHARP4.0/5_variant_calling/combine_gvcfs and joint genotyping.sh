#!/bin/bash
# Combine GVCF files for joint genotyping

GVCF_DIR="gvcf_files"
OUTPUT_DIR="combined_gvcfs"
REFERENCE="reference_genome.fa"
SAMPLE_MAP="sample_map.txt"

mkdir -p $OUTPUT_DIR

echo "Combining GVCF files"

# Create sample map file
> $SAMPLE_MAP
for gvcf in $GVCF_DIR/*.g.vcf.gz; do
    sample_id=$(basename $gvcf .g.vcf.gz)
    echo -e "$sample_id\t$gvcf" >> $SAMPLE_MAP
done

# Combine GVCFs
gatk CombineGVCFs \
    -R $REFERENCE \
    --variant $SAMPLE_MAP \
    -O $OUTPUT_DIR/combined.g.vcf.gz

echo "GVCF combination completed"

gatk GenotypeGVCFs \
    --java-options '-Xmx440G -DGATK_STACKTRACE_ON_USER_EXCEPTION=true' \
    -R /disk212/wangqy/1_DNAseq/index/susScr11.fa \
    --variant $OUTPUT_DIR/combined.g.vcf.gz \
    -O $OUTPUT_DIR/jointcall.vcf.gz