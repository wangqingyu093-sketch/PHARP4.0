#!/bin/bash
##GWAS
######filter
plink --file ./GWAS/intramuscularfat_suhuai/suhuai --geno 0.1 --mind 0.1 --maf 0.05 --allow-extra-chr --autosome --make-bed --out suhuai
######gemma
gemma -bfile ./GWAS/intramuscularfat_suhuai/suhuai -gk 2 -o kinship
gemma -bfile ./GWAS/intramuscularfat_suhuai/suhuai -k ./GWAS/intramuscularfat_suhuai/original/output/kinship.sXX.txt -lmm 1 -p ./GWAS/intramuscularfat_suhuai/pheno.txt -o output




#####filter
python3 liftover.py ./GWAS/intramuscularfat_suhuai/imputed/suhuai.bim
mv suhuai.bim suhuai.bim.bak
mv suhuai.bim.new.bim suhuai.bim
plink --bfile suhuai --allow-extra-chr --make-bed --out suhuai
plink --bfile suhuai --geno 0.1 --mind 0.1 --maf 0.05 --allow-extra-chr --autosome --make-bed --out suhuai
plink --bfile suhuai --list-duplicate-vars --out duplicates
plink --bfile suhuai --exclude duplicates.dupvar --make-bed --out cleaned_data
plink --bfile ./GWAS/intramuscularfat_suhuai/imputed/cleaned_data --geno 0.1 --snps-only --mind 0.1 --maf 0.05 --biallelic-only --allow-extra-chr --autosome --recode vcf --out suhuai
bgzip suhuai.vcf
tabix suhuai.vcf.gz
/disk191/zzy/software/local/bin/bcftools annotate --rename-chrs chr_name_change.txt suhuai.vcf.gz | bgzip -c > suhuaichr.vcf.gz
tabix suhuaichr.vcf.gz

######impute
for (( i = 1; i < 19; i++ )); do 
	java -jar conform-gt.jar ref=./panel/pharpv4/chr${i}.vcf.gz gt=suhuaichr.vcf.gz strict=false match=POS chrom=chr${i} out=suhuai.chr${i}.conform &
done
for (( i = 1; i < 19; i++ )); do
    beagle=/disk191_3/AnalysisPipline/Software/beagle.22Jul22.46e.jar	
    panel=./panel/pharpv4/chr${i}.vcf.gz
	java -jar -Xmx220g -Djava.io.tmpdir=./ ${beagle} gt=suhuai.chr${i}.conform.vcf.gz ref=${panel} chrom=chr${i} nthreads=3 out=suhuai.chr${i}.impute && tabix suhuai.chr${i}.impute.vcf.gz &
done
find ./GWAS/intramuscularfat_suhuai/ -name "*impute.vcf.gz" | sort -V > mergeimpute_list.txt
bcftools concat -a -d all -f mergeimpute_list.txt -o suhuai.chrall.impute.vcf && bgzip suhuai.chrall.impute.vcf && tabix suhuai.chrall.impute.vcf.gz &
plink --vcf suhuai.chrall.impute.vcf.gz --maf 0.05 --allow-extra-chr --autosome --make-bed --out suhuai.chrall.impute &

######gemma
gemma -bfile ./GWAS/intramuscularfat_suhuai/suhuaichr -gk 2 -o kinship
gemma -bfile ./GWAS/intramuscularfat_suhuai/suhuaichr -c fixed.txt -k ./GWAS/intramuscularfat_suhuai/original/output/kinship.sXX.txt -lmm 1 -p ./GWAS/intramuscularfat_suhuai/pheno.txt -o output

######gemma

gemma -bfile ./GWAS/intramuscularfat_suhuai/suhuai.chrall.impute -gk 2 -o kinship
gemma -bfile ./GWAS/intramuscularfat_suhuai/suhuai.chrall.impute -c fixed.txt -k ./GWAS/intramuscularfat_suhuai/imputed/output/kinship.sXX.txt -lmm 1 -p ./GWAS/intramuscularfat_suhuai/pheno.txt -o output
