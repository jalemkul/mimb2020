#!/usr/bin/perl

use strict;

# check_drude_lengths.pl - parse thru a coordinate file and check all Drude-atom bonds,
# flagging any that are longer than 0.2 A. This is useful for evaluating the outcome of
# energy minimization. Sometimes the systems are over-minimized or otherwise unstable,
# and this kind of check will point to where the problem might lie.

unless (scalar(@ARGV)==2)
{
    die "Usage: perl $0 input.pdb/crd tolerance\n";
}

my $input = $ARGV[0];
my $toler = $ARGV[1]; 
my $toler2 = $toler * $toler;

open(IN, "<$input") || die "Cannot open $input: $!\n";
my @in = <IN>;
close(IN);

# determine what kind of file type we have
my $type = 0;
if ($input =~ /(\w+).pdb/)
{
    $type = 0;
    # debug
    print "File type detected: PDB\n";
}
elsif ($input =~ /(\w+).crd/)
{
    $type = 1;
    # debug
    print "File type detected: CRD\n";
}
else
{
    die "Unknown file type provided as input.\n";
}

# Since PDB files can vary in the number of fields they have (if there are chain identifiers,
# occupancy, B-factors, segid, etc. the parsing is done based on standard PDB format only using
# substrings. Here, we need atom names (fields 13 - 16) and (x,y,z) coordinates
#   x: fields 31 - 38
#   y: fields 39 - 46
#   z: fields 47 - 54
# Note that substr uses the index (so, field - 1) and the length of the field to read
if ($type == 0)
{
    for (my $i=0; $i<scalar(@in); $i++)
    {
        if ($in[$i] =~ /ATOM/)
        {
            my $atname = substr $in[$i], 12, 4;
            $atname =~ s/\s//g;
            my $atnumi = substr $in[$i], 4, 7;
            my $x = substr $in[$i], 30, 8;
            my $y = substr $in[$i], 38, 8;
            my $z = substr $in[$i], 46, 8;

            my @tmp = split('', $atname);

            # debug
            #print "atname: $atname x: $x y: $y z: $z (char: $tmp[0])\n";

            if ($tmp[0] eq "D")
            {
                # debug
                #print "Checking Drude $atname\n";

                my $j = $i - 1;
                # we have a Drude, so get information about parent atom
                my $atname2 = substr $in[$j], 12, 4;
                $atname2 =~ s/\s//g;
                my $atnumj = substr $in[$j], 4, 7;
                my $x2 = substr $in[$j], 30, 8;
                my $y2 = substr $in[$j], 38, 8;
                my $z2 = substr $in[$j], 46, 8;

                # debug
                #print "atname2: $atname2 x: $x2 y: $y2 z: $z2\n";

                my $dx = $x - $x2;
                my $dy = $y - $y2;
                my $dz = $z - $z2;

                my $dist2 = ($dx*$dx) + ($dy*$dy) + ($dz*$dz);

                if ($dist2 > $toler2)
                {
                    printf "Atom %d (%s) and Drude %d (%s) are %.3f A apart!\n", ($atnumj), $atname2, ($atnumi), $atname, sqrt($dist2);
                }
            }
        }
    }
}
# CRD file format is a bit easier to deal with, so we can just split into fields.
else
{
    # Lines starting with '*' are comments, after which there is one line with number of atoms
    # So in this loop, just prune off any arbitrary number of comments, plus one more line
    for (my $i=0; $i<scalar(@in); $i++)
    {
        if ($in[$i] =~ /\*/)
        {
            shift(@in);
            $i--;
        }    
    }
    # now remove the line w/number of atoms
    shift(@in);

    # now everything in @in is just atom entries
    for (my $i=0; $i<scalar(@in); $i++)
    {
        my @line = split(" ", $in[$i]);
        my $atname = $line[3];
        my $x = $line[4];
        my $y = $line[5];
        my $z = $line[6];

        # debug
        # print "atname: $atname x: $x y: $y z: $z\n";

        my @tmp = split('', $atname);
        if ($tmp[0] eq "D")
        {
            # debug
            # print "Checking Drude $atname\n";

            my $j = $i - 1;

            # get information about parent atom
            my @line2 = split(" ", $in[$j]);
            my $atname2 = $line2[3];
            my $x2 = $line2[4];
            my $y2 = $line2[5];
            my $z2 = $line2[6];

            my $dx = $x - $x2;
            my $dy = $y - $y2;
            my $dz = $z - $z2;

            my $dist2 = ($dx*$dx) + ($dy*$dy) + ($dz*$dz);

            if ($dist2 > $toler2)
            {
                printf "Atom %d (%s) and Drude %d (%s) are %.3f A apart!\n", ($j+1), $atname2, ($i+1), $atname, sqrt($dist2);
            }
        }
    }
}

exit;
