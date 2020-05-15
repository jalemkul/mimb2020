#!/usr/bin/perl

# namd2omm.pl - a script to write a restart file for OpenMM to continue a NAMD run
#
#   input:
#       1. coor file
#       2. vel file
#       3. xsc file (for box vectors)
#
# 3/8/2016 Justin Lemkul (jalemkul@outerbanks.umaryland.edu)

unless (scalar(@ARGV)==3)
{
    die "Usage: perl $0 md.coor md.vel md.xsc\n";
}

my $coor = $ARGV[0];
my $vel = $ARGV[1];
my $xsc = $ARGV[2];

print "Reading coordinates from: $coor\n";
print "Reading velocities from: $vel\n";
print "Reading box vectors from: $xsc\n";

# open coordinates and velocities
open(INCOORD, "<$coor") || die "Cannot open coordinate file: $!\n";
my @inx = <INCOORD>;
close(INCOORD);

open(INVEL, "<$vel") || die "Cannot open velocity file: $!\n";
my @inv = <INVEL>;
close(INVEL);

# sanity check
my $nx = scalar(@inx);
my $nv = scalar(@inv);
if ($nx != $nv)
{
    die "Number of coordinate entries ($nx) does not match number of velocity entries ($nv).\nHave you given the files in right order?\n"; 
}

# output
open(OUT, ">omm.rst") || die "Cannot open output file: $!\n";

# print header
print OUT "<?xml version=\"1.0\" ?>\n";

# get the box first
open(INBOX, "<$xsc") || die "Cannot open box file: $!\n";
my @inbox = <INBOX>;
close(INBOX);

# there should only be one relevant line in the file, anyway, so 
# we just grab the last entry
my $line = $inbox[scalar(@inbox)-1];
my @tmp = split(" ", $line);
my $time = $tmp[0] / 1000;  # assume 1-fs dt during MD to convert nsteps to time in ps
my $boxx = $tmp[1] / 10.0;  # OpenMM uses nm as its box vector unit
my $boxy = $tmp[5] / 10.0;
my $boxz = $tmp[9] / 10.0;
printf OUT "<State openmmVersion=\"7.0\" time=\"%.15f\" type=\"State\" version=\"1\">\n", $time;
print OUT "\t<PeriodicBoxVectors>\n";
printf OUT "\t\t<A x=\"%.15f\" y=\"0\" z=\"0\"/>\n", $boxx;
printf OUT "\t\t<B x=\"0\" y=\"%.15f\" z=\"0\"/>\n", $boxy;
printf OUT "\t\t<C x=\"0\" y=\"0\" z=\"%.15f\"/>\n", $boxz;
print OUT "\t</PeriodicBoxVectors>\n";

# write the coords
print OUT "\t<Positions>\n";
for (my $i=0; $i<$nx; $i++)
{
    if ($inx[$i] =~ /ATOM/)
    {
        my @tmp = split(" ", $inx[$i]);
        # OpenMM uses nm as its units
        my $x = $tmp[5] / 10.0;
        my $y = $tmp[6] / 10.0;
        my $z = $tmp[7] / 10.0;
        printf OUT "\t\t<Position x=\"%.15f\" y=\"%.15f\" z=\"%.15f\"/>\n", $x, $y, $z;
    }
}
print OUT "\t</Positions>\n";

# write the velocities
print OUT "\t<Velocities>\n";
for (my $i=0; $i<$nv; $i++)
{   
    if ($inv[$i] =~ /ATOM/)
    {   
        my @tmp = split(" ", $inv[$i]);
        # OpenMM uses nm/ps as its units
        my $x = $tmp[5] / 10.0;
        my $y = $tmp[6] / 10.0;
        my $z = $tmp[7] / 10.0;
        printf OUT "\t\t<Velocity x=\"%.15f\" y=\"%.15f\" z=\"%.15f\"/>\n", $x, $y, $z;
    }
}
print OUT "\t</Velocities>\n";

# finish the file
print OUT "</State>\n";
close(OUT);
exit;
