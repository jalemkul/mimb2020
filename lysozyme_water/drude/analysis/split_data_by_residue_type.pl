#!/usr/bin/perl

use strict;

# Read in two files and separate the data based on amino acid type
#   1. Residue name list (single column, 3-character, all caps)
#   2. Data file (x = residue, y = data of interest)
#
# Writes out:
#   1. aliphatic.dat (Ala, Ile, Leu, Met, Pro, Val)
#   2. aromatic.dat (Phe, Trp, Tyr)
#   3. polar_neutral.dat (Asn, Cys, Gln, Gly, Hse, Hsd, Ser, Thr)
#   4. positive.dat (Arg, Hsp, Lys)
#   5. negative.dat (Asp, Glu)

unless (scalar(@ARGV)==2)
{
    die "Usage: perl $0 resnames.dat datafile.dat\n";
}

my $resfile = $ARGV[0];
my $datafile = $ARGV[1];

open(IN1, "<$resfile") || die "Cannot open $resfile: $!\n";
my @res = <IN1>;
close(IN1);

open(IN2, "<$datafile") || die "Cannot open $datafile: $!\n";
my @data = <IN2>;
close(IN2);

# open output files
open(OUT1, ">aliphatic.dat");
open(OUT2, ">aromatic.dat");
open(OUT3, ">polar_neutral.dat");
open(OUT4, ">positive.dat");
open(OUT5, ">negative.dat");

# loop through both files and decide which file will be written to
# first, sanity check
my $nres = scalar(@res);
my $ndata = scalar(@data);

if ($nres != $ndata)
{
    die "Number of lines in provided files is unequal!\n";
}

for (my $i=0; $i<$nres; $i++)
{
    # get residue name from first file
    chomp($res[$i]);
    my $resn = $res[$i];

    # based on residue name, print matching data line to the appropriate file
    if ( ($resn =~ /ALA/) || ($resn =~ /ILE/) || ($resn =~ /LEU/) || ($resn =~ /MET/) || ($resn =~ /PRO/) || ($resn =~ /VAL/) )
    {
        print OUT1 $data[$i];
    }
    elsif ( ($resn =~ /PHE/) || ($resn =~ /TRP/) || ($resn =~ /TYR/) )
    {
        print OUT2 $data[$i];
    }
    elsif ( ($resn =~ /ASN/) || ($resn =~ /CYS/) || ($resn =~ /GLN/) || ($resn =~ /GLY/) || ($resn =~ /HSD/) || ($resn =~ /HSE/) || ($resn =~ /HIS/) || ($resn =~/SER/) || ($resn =~ /THR/) )
    {
        print OUT3 $data[$i];
    }
    elsif ( ($resn =~ /ARG/) || ($resn =~ /HSP/) || ($resn =~ /LYS/) )
    {
        print OUT4 $data[$i]; 
    }
    elsif ( ($resn =~ /ASP/) || ($resn =~ /GLU/) )
    {
        print OUT5 $data[$i]; 
    }
    else
    {
        die "Unknown residue $resn\n";
    }
}

close(OUT1);
close(OUT2);
close(OUT3);
close(OUT4);
close(OUT5);

exit;
