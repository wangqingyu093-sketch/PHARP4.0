#!/usr/bin/perl
# Merge BAM files for samples with multiple sequencing runs

use strict;
use warnings;

my $sample_list = "sample_list.txt";
my $bam_dir = "aligned_bams";
my $merged_dir = "merged_bams";
my $threads = 15;

system("mkdir -p $merged_dir");

open(my $fh, '<', $sample_list) or die "Cannot open $sample_list: $!";

my %sample_bams;

while (my $line = <$fh>) {
    chomp $line;
    my @fields = split(/\t/, $line);
    my $sample_id = $fields[0];
    my $seq_id = $fields[1];
    
    my $bam_file = "$bam_dir/${seq_id}.sorted.bam";
    if (-e $bam_file) {
        push @{$sample_bams{$sample_id}}, $bam_file;
    }
}

close($fh);

foreach my $sample_id (keys %sample_bams) {
    my @bams = @{$sample_bams{$sample_id}};
    
    if (scalar @bams == 1) {
        print "Copying single BAM for $sample_id\n";
        system("cp $bams[0] $merged_dir/${sample_id}.merged.bam");
    } else {
        print "Merging " . scalar @bams . " BAMs for $sample_id\n";
        my $bam_list = join(' ', @bams);
        system("samtools merge -@ $threads $merged_dir/${sample_id}.merged.bam $bam_list");
        system("samtools sort -O bam -@ $threads -o $merged_dir/${sample_id}.merged.sort.bam $merged_dir/${sample_id}.merged.bam");
    }
    
    system("samtools index $merged_dir/${sample_id}.merged.sort.bam");
}

print "BAM merging completed\n";