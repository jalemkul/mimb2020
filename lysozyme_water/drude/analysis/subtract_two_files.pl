#!/bin/perl

use strict;

# This script subtracts the values in file 2 from those in file 1

unless (@ARGV)
{
    die "Usage: perl $0 file1.dat/.xvg file2.dat/.xvg\n";
}

my $file1 = $ARGV[0];
my $file2 = $ARGV[1];

print "Reference values are being taken from $file1\n";
print "Values in $file2 will be subtracted from those in $file1\n";

open(IN, "<$file1") || die "Cannot open $file1: $!\n";
my @in1 = <IN>;
close(IN);

open(IN, "<$file2") || die "Cannot open $file2: $!\n";
my @in2 = <IN>;
close(IN);

my $nentry1 = scalar(@in1);
my $nentry2 = scalar(@in2);

# make sure the number of lines is equal
if ($nentry1 != $nentry2)
{
    print "Number of entries unequal!\n";
    print "$nentry1 in $file1 and $nentry2 in $file2\n";
    die;
}

# open output file for writing
open(OUT, ">diff.dat") || die "Cannot open output file: $!\n";

for (my $i=0; $i<$nentry1; $i++)
{

    my $line1 = $in1[$i];
    my $line2 = $in2[$i];

    chomp($line1);
    chomp($line2);

    # assume that both files have the same number of comment lines
    unless ($line1 =~ /[#@]/)
    {
        my @data1 = split(" ", $line1);
        my @data2 = split(" ", $line2);

        if ($data1[0] == $data2[0])
        {
            my $diff = $data1[1] - $data2[1];
            printf OUT "%8.3f\t%10.6f\n", $data1[0], $diff;
        }
    }
}

close(OUT);
exit;
