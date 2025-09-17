#!/usr/bin/perl
###rmDUP,bamQC,addRG；

open(LIST,"sample_list.txt")or die "cannot open sample_list";
@lists=<LIST>;
$bam_dir = "./2_bam/"; ### input bam
$bam_clean_dir = "./4_clean_bam/"; ### output clean bam

mkdir "$bam_clean_dir" unless -e "$bam_clean_dir";

for ($i=1;$i<=14;$i++){#check
    chomp;
    $list = $lists[$i];
    $list=~s/[\r\n]//g;
    @list_array = split(/\t/,$list);
    $sample_name = $list_array[1];

    $ID=$sample_name;
    $LB="SHZ";
    $PL="ILLUMINA";
    $SM=$sample_name;
    $PU="ILLUMINA";

    $bam_input = $bam_dir.$sample_name.".sort.bam";

    $file_bam_rmUdup=$bam_clean_dir.$sample_name.".rmDup.sorted.bam";
    $file_bai_rmUdup=$bam_clean_dir.$sample_name.".rmDup.sorted.bam.bai";

    $file_bam_addRG=$bam_clean_dir.$sample_name.".rmDup.addRG.sorted.bam";
    $file_bam_sort=$bam_clean_dir.$sample_name.".rmDup.addRG.rmUnmap.sorted.bam";

    if(-s $file_bam_sort){
        print "number:$i\t$sample_name\n";
        print "WARN: $file_bam_sort exist\n";

    }else{
        print "number:$i\t$sample_name\n";

        system("sambamba markdup -r --tmpdir=$bam_clean_dir --overflow-list-size 1000000 --hash-table-size 1000000  $bam_input  $file_bam_rmUdup -t 15");
        system("samtools addreplacerg -r  ID:$ID -r LB:$LB -r PL:$PL -r SM:$SM -r PU:$PU  -@ 15 -o $file_bam_addRG $file_bam_rmUdup ");
        system("sambamba view  -p -h -t 15 -f bam  -F  'not unmapped'  -o $file_bam_sort $file_bam_addRG ");

        if(-s $file_bam_sort){
            system("rm $file_bam_rmUdup $file_bai_rmUdup $file_bam_addRG");
        }else{
            print "ERROR: $file_bam_sort can't create\n";
        }
    }

}

close LIST;