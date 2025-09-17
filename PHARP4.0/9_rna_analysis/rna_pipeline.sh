#!/usr/bin/perl
######
open(LIST,"sample_list.txt") or die "cannot open aaa";
@lists=<LIST>;
### change the path to your file
$work_dir = "./";
$dir_qc_out ="$work_dir/1_fastp";
$dir_bam_out ="$work_dir/2_bam";
$bam_clean_dir = "$work_dir/3_clean_bam";
$bqsrpath ="$work_dir/6_bqsr";
$gvcfpath ="$work_dir/7_gvcf";
$gtxvcfpath ="$work_dir/8_vcf";

mkdir "$dir_qc_out" unless -e "$dir_qc_out";
mkdir "$dir_bam_out" unless -e "$dir_bam_out";
mkdir "$bam_clean_dir" unless -e "$bam_clean_dir";
mkdir "$bqsrpath" unless -e "$bqsrpath";
mkdir "$gvcfpath" unless -e "$gvcfpath";
mkdir "$gtxvcfpath" unless -e "$gtxvcfpath";
open(TSV,">$work_dir/8_vcf/sample_gvcf_map.tsv");

for ($i=0;$i<=$#lists;$i++){
	print "number:$i\n";
	chomp;
	$list = $lists[$i];
	$list=~s/[\r\n]//g;
	@list_array = split(/\t/,$list);
	##根据sample_list.txt 确定0和1
	$sample_name = $list_array[0];
	$fastq_file = $list_array[1];

	$file_fastq1=$fastq_file."_1.fastq.gz";
	$file_fastq2=$fastq_file."_2.fastq.gz";
	if(!-s $file_fastq1){
		$file_fastq1=$fastq_file."_1.clean.fq.gz";
		$file_fastq2=$fastq_file."_2.clean.fq.gz";
	}
	print "fastqName\t".$file_fastq1."_".$file_fastq2."\n";


	# 1 fastp
	$file_j=$dir_qc_out.'/'.$sample_name.".json";
    $file_h=$dir_qc_out.'/'.$sample_name.".html";
	$file_fastq1_qc=$dir_qc_out.'/'.$sample_name."_qc_1.fastq.gz";
	$file_fastq2_qc=$dir_qc_out.'/'.$sample_name."_qc_2.fastq.gz";
    if(!-s $file_fastq1_qc){
		    ###pair
			if(-s $file_fastq1 && -s  $file_fastq2){
					###pair add -A
					system("fastp -i $file_fastq1 -I $file_fastq2  -o $file_fastq1_qc  -O $file_fastq2_qc -w 20 -j $file_j  -h $file_h ");
			}else{
					print "ERROR: $file_fastq1 \t $file_fastq2 doesn't exsit\n";
			}
	}else{
			print "$file_fastq1_qc exist\n";
	}


	# 2 star samtools
	$file_sam = $dir_bam_out .'/'.$sample_name;
	$file_bam_sort = $dir_bam_out .'/'.$sample_name.'.sort.bam';
	if(!-s $file_bam_sort){
			if(-s $file_fastq1_qc && -s $file_fastq2_qc){
					system("STAR --runThreadN  50  --genomeDir STARindex --twopassMode Basic --outReadsUnmapped None --chimSegmentMin 12 --alignIntronMax 100000 --chimSegmentReadGapMax parameter 3 --alignSJstitchMismatchNmax 5 -1 5 5 --readFilesCommand zcat --readFilesIn $file_fastq1_qc $file_fastq2_qc --outFileNamePrefix  $file_sam  ");
					system("samtools view  -@ 20  -bS ${file_sam}Aligned.out.sam | samtools sort  -@ 20 -o $file_bam_sort ");
					system("samtools index $file_bam_sort ");
			}else{
					print "ERROR: $file_fastq1_qc\t $file_fastq2_qc doesn't exsit\n";
			}

	}else{
			print "$file_bam_sort exist\n";
	}


	# 3 sambamba SplitNCigarReads
	$ID=$sample_name;
    $LB="RNA";
    $PL="ILLUMINA";
    $SM=$sample_name;
    $PU="Illumina";
    $file_bam_rmUdup=$bam_clean_dir.'/'.$sample_name.".rmDup.sorted.bam";
    $file_bai_rmUdup=$bam_clean_dir.'/'.$sample_name.".rmDup.sorted.bam.bai";
    $file_bam_addRG=$bam_clean_dir.'/'.$sample_name.".rmDup.addRG.sorted.bam";
    $file_bam_final=$bam_clean_dir.'/'.$sample_name.".rmDup.addRG.rmUnmap.sorted.bam";
    $file_bam_final_tmp=$bam_clean_dir.'/'.$sample_name.".tmp.rmDup.addRG.rmUnmap.sorted.bam";
	if(!-s $file_bam_final){
    		print "number:$i\t $file_bam_final doesn't exist\n";
      		if(-s $file_bam_sort){
    				print "number:$i\t$sample_name\n";
          			system("sambamba  markdup -r --tmpdir=$bam_clean_dir --overflow-list-size 1000000 --hash-table-size 1000000  $file_bam_sort  $file_bam_rmUdup -t 30");
         			system("samtools addreplacerg -r  ID:$ID -r LB:$LB -r PL:$PL -r SM:$SM -r PU:$PU  -@ 15 -o $file_bam_addRG $file_bam_rmUdup ");
          			system("sambamba  view  -p -h -t 30 -f bam  -F  'not unmapped'  -o $file_bam_final_tmp $file_bam_addRG ");
          			system("gatk --java-options \"-Djava.io.tmpdir=./\" SplitNCigarReads --spark-runner LOCAL -R /susScr11.fa  -I $file_bam_final_tmp -O $file_bam_final ");
          			system("samtools index $file_bam_final ");
          			if(-s $file_bam_final){
              				system("rm $file_bam_rmUdup $file_bai_rmUdup $file_bam_addRG");
          			}else{
              		print "ERROR: $file_bam_final can't create\n";
          			}
        	}else{
					print "ERROR: $file_bam_sort doesn't exsit\n";
			}
    }else{
        	print "number:$i\t $file_bam_final exist\n";
    }


	# 4 BQSR
    $bqsrOutBam=$bqsrpath.'/'.$sample_name.".bam";
	$bqsrOutrecal=$bqsrpath.'/'.$sample_name.".bam.recal.grp";
    if(!-s $bqsrOutBam ){
		    if(-s $file_bam_final){
            		system("gatk --java-options \"-Djava.io.tmpdir=/tmp\" BaseRecalibrator --spark-runner LOCAL -I $file_bam_final -R  /susScr11.fa --known-sites /dbsnp/pig_indel_build150.vcf.gz --known-sites /dbsnp/pig_snp_build150.vcf.gz -O $bqsrOutrecal ");
            		system("gatk ApplyBQSR --spark-runner LOCAL -R /susScr11.fa -I $file_bam_final  --bqsr-recal-file $bqsrOutrecal -O $bqsrOutBam");
					
					print "ERROR: $file_bam_final doesn't exsit\n";
			}
	}else{
    	    print "WARN: $bqsrOutBam exist\n";
	}


	# 5 gtx gvcf
	$dir_gvcf=$gvcfpath.'/'.$sample_name;
	mkdir "$dir_gvcf" unless -e "$dir_gvcf";
	$gtxgvcf=$dir_gvcf.'/'.$sample_name.".g.vcf.gz";
	if(!-s $gtxgvcf ){
			if(-s $bqsrOutBam){
					system("gtx vc -r /susScr11.fa -i $bqsrOutBam -o $gtxgvcf -t 50 -g ");
			}else{
					print "ERROR: $bqsrOutBam doesn't exsit\n";
			}
    }else{
    	    print "WARN: $gtxgvcf exist\n";
	}


	# 6 gtx call snp
	$dir_vcf=$gtxvcfpath.'/'.$sample_name;
	mkdir "$dir_vcf" unless -e "$dir_vcf";
	$gtxvcf=$dir_vcf.'/'.$sample_name.".vcf.gz";
	if(!-s $gtxvcf ){
			if(-s $gtxgvcf){
					system("gtx joint -v $gtxgvcf -r /susScr11.fa -t 50 -o $gtxvcf");
			}else{
					print "ERROR: $gtxgvcf doesn't exsit\n";
			}
    }else{
    	    print "WARN: $gtxvcf exist\n";
	}
	print TSV "$sample_name\t$gtxgvcf\n";
}

# 7 gtx joint call
$jointcallvcf=$gtxvcfpath.'/chrall.vcf.gz';
if(!-s $jointcallvcf ){
		system("gtx joint --sample-name-map $work_dir/8_vcf/sample_gvcf_map.tsv -r /susScr11.fa -t 10 -o $jointcallvcf");
}else{
    	print "WARN: $jointcallvcf exist\n";
}

print "END\n";
close TSV;
close LIST;
