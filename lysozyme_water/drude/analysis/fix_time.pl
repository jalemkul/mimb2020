#!/usr/bin/perl 

# This script converts the output of a GROMACS-processed NAMD DCD trajectory
# and fixes the time values.  The GROMACS tools do not read time information from
# the DCD file, thus all values are printed as zero.
#
# This script reads in two parameters, initial time and frame interval (usually in
# ps, but it can be anything) and substitutes the zero value for the correct one.
#

use strict;

unless (scalar(@ARGV)==3) {
    die "Usage: perl $0 input.xvg start_time frame_interval\n";
}

my $input = $ARGV[0];

my $start_t = $ARGV[1];
my $frame_t = $ARGV[2];
my @out = split('\.', $input);
my $base_out = $out[0];     # assumes no other . than in the extension
my $outfile = $base_out."_fix.xvg";

open(IN, "<$input") || die "Cannot open $input: $!\n";
my @inlines = <IN>;
close(IN);

# clean up header stuff and write directly to the output file
open(OUT, ">$outfile") || die "Cannot open $outfile: $!\n";

my $size = scalar(@inlines);

for (my $i=0; $i<$size; $i++) {
    if ($inlines[$i] =~ /^[#@]/) {
        my $tmp = shift(@inlines);
        print OUT $tmp;
        $i--;
        $size--;
    }
}

# now, @inlines should only have actual data lines

# debug
#open(TMP, ">tmp");
#foreach $_ (@inlines) {
#    print TMP $_;
#}
#close(TMP);

for (my $i=0; $i<scalar(@inlines); $i++) {

    my $real_time = ($i * $frame_t) + $start_t;

    my $tmpline = $inlines[$i];
    my @data = split(" ", $tmpline);
    my $out_string = "";
    for (my $j=1; $j<(scalar(@data)); $j++)
    {
        $out_string .= "\t".$data[$j];
    }
    # my $data_pt = $data[1];     # assume two-column output (time and data)
    # printf OUT "%8.4f\t%8.4f\n", $real_time, $data_pt;
    printf OUT "%8.4f\t%s\n", $real_time, $out_string;
}

close(OUT);

exit;
