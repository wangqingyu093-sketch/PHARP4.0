#!/usr/bin/perl
#Variant calling with GATK HaplotypeCaller

my $chr=$ARGV[0];
my $thread=$ARGV[1];

open(AAA,"sample_list.txt") or die "cannot open sample_list";
@aa=<AAA>;

$bam_clean_dir="./4_clean_bam"; ##input
$dir_gVCF="./5_gVCF"; ##output
mkdir "$dir_gVCF" unless -e "$dir_gVCF";

for ($num=1;$num<=$#aa;$num++){
    chomp $aa[$num];
    $aa[$num]=~s/[\r\n]//g;
    @arr1=split(/\t/,$aa[$num]);
    print "$chr\n";
    $sample_name=$arr1[1];
    $dir_pro_sample=$dir_gVCF."/".$sample_name;
    mkdir "$dir_pro_sample" unless -e "$dir_pro_sample";

    $file_bam_sort=$bam_clean_dir."/".$sample_name.".rmDup.addRG.rmUnmap.sorted.bam";
    $file_gVCF_chr=$dir_pro_sample."/".$sample_name."_".$chr."_gVCF.gz";
    $file_gVCF_chr_tbi=$dir_pro_sample."/".$sample_name."_".$chr."_gVCF.gz.tbi";

    if(-s $file_bam_sort){

        if(-s $file_gVCF_chr){

        }else{
            print "$sample_name do not exist;";
            system("gatk --java-options '-Xmx10G -DGATK_STACKTRACE_ON_USER_EXCEPTION=true' HaplotypeCaller -R susScr11.fa --read-filter GoodCigarReadFilter  -I $file_bam_sort -O $file_gVCF_chr  -L $chr --native-pair-hmm-threads $thread --sample-ploidy 2 --emit-ref-confidence GVCF ");
        }
    }else{
        print  "$file_bam_sort do not exists;\n";
    }

}
 
close AAA;