#!/usr/bin/perl

use strict;

# write_B-factors.pl
#   Program reads in a PDB file and writes a value to the B-factor field
#   This program is intended to be used to produce NAMD input, which reads force constants
#   from the desired column (I like the B-factor field).
#
#   The force constant is read as a command-line argument.
#
#   Due to the complexity of line parsing, this script can produce
#   incorrect output from time to time, so the user is cautioned to
#   check the resulting PDB file very carefully.
#
#   Considered a WIP. Last update: 11/12/2013
#

unless (scalar(@ARGV)==2)
{
    die "Usage: perl $0 pdbfile force_constant\n";
}

my $infile = $ARGV[0];
my $fc = $ARGV[1];

# debug
print "Force constant being set to: $fc\n";

# some helpful information
print "This script produces wonky output sometimes because it is needlessly complex.\n";
print "Check your output carefully to make sure it agrees with your expectations.\n";
print "You have been warned!\n";

open(IN, "<$infile") || die "Cannot open $infile: $!\n";
my @in = <IN>;
close(IN);

open(OUT, ">restraint.pdb") || die "Cannot open output file: $!\n";

foreach $_ (@in)
{

    chomp($_);

    unless (($_ =~ /ATOM/) || ($_ =~ /HETATM/))
    {
        # write REMARKS, TER, CONECT, etc as they are
        print OUT "$_\n";        
    } else {      

        # define variables to hold information from each line
        # purposefully not saving B-factor because the script writes a new one anyway
        my $atom;       # ATOM or HETATM
        my $atnr;       # atom number
        my $atname;     # atom name
        my $resn;       # residue name
        my $ch;         # chain id
        my $resnr;      # residue number
        my $x;          # x coord
        my $y;          # y coord
        my $z;          # z coord
        my $occ;        # occupancy field
        my $last;       # last field - chain name, atom name, etc

        # separate all the fields on each line
        my @entries = split(" ", $_);

        # Here, the script needs to be smart - a PDB file may or may not contain
        # chain identifiers and extra fields (segment names, atom types, etc) at the end
        # Need to determine the size of @entries and whether or not there is a chain
        # identifier written, which is the most important test since the remaining fields
        # will be affected by its presence or absence

        if (scalar(@entries)==12)
        {
            # we have a chain identifier and an additional field at the end
            $atom = $entries[0];
            $atnr = $entries[1];
            $atname = $entries[2];
            $resn = $entries[3];
            $ch = $entries[4];
            $resnr = $entries[5];
            $x = $entries[6];
            $y = $entries[7];
            $z = $entries[8];
            $occ = $entries[9];
            $last = $entries[11];
        } elsif (scalar(@entries)==11) {

            # 4-character residue names screw things up since the residue name and chain
            # are continuous, so some manual reassignment may be necessary (e.g., TIP3)

            my @shift_entries;
            my @test = split('', $entries[3]);

            if (scalar(@test)==5)
            {
                my @tmp = split('', $entries[3]);
                my $tmp_resn = join('', $tmp[0], $tmp[1], $tmp[2], $tmp[3]);
                my $tmp_ch = $tmp[4];

                # re-position trailing entries
                for (my $i=(scalar(@entries)+1); $i>3; $i--)
                {
                    $entries[$i] = $entries[$i-1];
                }

                # need to create new array to store shifted values
                for (my $i=0; $i<(scalar(@entries)+1); $i++)
                {
                    if ($i<=2) {
                        $shift_entries[$i] = $entries[$i];
                    } elsif ($i==3) {
                        $shift_entries[$i] = $tmp_resn;
                    } elsif ($i==4) {
                        $shift_entries[$i] = $tmp_ch;
                    } else {
                        $shift_entries[$i] = $entries[$i];
                    }
                }

            } else {
                for (my $j=0; $j<scalar(@entries); $j++) 
                {
                    $shift_entries[$j] = $entries[$j];
                }
            }

            if ($shift_entries[4] =~ /[A-Z]/)
            {
                # we have a chain identifier, no field at end
                # debug
                # print "Found a chain identifier!\n";
                $atom = $shift_entries[0];
                $atnr = $shift_entries[1];
                $atname = $shift_entries[2];
                $resn = $shift_entries[3];
                $ch = $shift_entries[4];
                $resnr = $shift_entries[5];
                $x = $shift_entries[6];
                $y = $shift_entries[7];
                $z = $shift_entries[8];
                $occ = $shift_entries[9]; 
                $last = " ";
            } else {
                # no chain identifier, extra field at end
                # debug
                # print "No chain identifier found.\n";
                $atom = $shift_entries[0];
                $atnr = $shift_entries[1];
                $atname = $shift_entries[2];
                $resn = $shift_entries[3];
                $ch = " ";
                $resnr = $shift_entries[4];
                $x = $shift_entries[5];
                $y = $shift_entries[6];
                $z = $shift_entries[7];
                $occ = $shift_entries[8];
                $last = $shift_entries[10];
            }
        } else {
            # 9 fields, no chain identifier, no extra field
            $atom = $entries[0];
            $atnr = $entries[1];
            $atname = $entries[2];
            $resn = $entries[3];
            $ch = " ";
            $resnr = $entries[4];
            $x = $entries[5];
            $y = $entries[6];
            $z = $entries[7];
            $occ = $entries[8];
            $last = " ";
        }

        # only write new B-factors for non-water, non-ion, non-H, non-Drude, non-LP particles
        my @atomchar = split('', $atname);
        my $is_h = 0;
        my $is_drude = 0;
        my $is_lp = 0;

        if ($atomchar[0] =~ /H/)
        {
            # debug
            # print "Atom name $atname is a hydrogen.\n";
            $is_h = 1;
        }

        if ($atomchar[0] =~ /D/)
        {
            # debug
            # print "Atom name $atname is a drude.\n";
            $is_drude = 1;
        }

        if (($atomchar[0] =~ /L/) && ($atomchar[1] =~ /P/))
        {
            # debug
            # print "Atom name $atname is a lone pair.\n";
            $is_lp = 1;
        }

        if (($resn =~ /SOL/) || ($resn =~ /HOH/) || ($resn =~ /TIP3/) || ($is_h == 1) || ($resn =~ /POT/) || ($resn =~ /POPC/) ||
            ($resn =~ /SOD/) || ($resn =~ /CLA/) || ($resn =~ /CAL/) || ($resn =~ /NA/) || ($resn =~ /LI/) || ($is_drude == 1)
            || ($is_lp == 1) || ($resn =~ /SWM/) || ($resn =~ /ETOH/))
        {
            # we don't want to restrain mobile ions, but we may want to restrain heteroatoms
            # that are bound to biomolecular structures
            unless ($last =~ /HETA/ && ($is_lp == 0) && ($is_drude == 0))
            {
                # debug
                # print "Res name: $resn Atom name: $atname Atomchar: $atomchar[0] Drude: $is_drude LP: $is_lp H: $is_h setting fc = 0\n";
                printf OUT "%-6s%5d%5s%4s%1s%5d    %8.3f%8.3f%8.3f%6.2f%6.2f%10s\n", $atom, $atnr, $atname, $resn, $ch, $resnr, $x, $y, $z, $occ, 0, $last;
            }
            else
            {
                printf OUT "%-6s%5d%5s%4s%1s%5d    %8.3f%8.3f%8.3f%6.2f%6.2f%10s\n", $atom, $atnr, $atname, $resn, $ch, $resnr, $x, $y, $z, $occ, $fc, $last;
            }
        } else {
            # it is a solute (protein or nucleic acid) atom
            # debug
            # print "Atom name: $atname setting fc = $fc\n";
            printf OUT "%-6s%5d%5s%4s%1s%5d    %8.3f%8.3f%8.3f%6.2f%6.2f%10s\n", $atom, $atnr, $atname, $resn, $ch, $resnr, $x, $y, $z, $occ, $fc, $last;
        }
    }
}

print "Restraint file \"restraint.pdb\" has been written.\n";
print "Drudes, LPs, and H atoms were NOT assigned the force constant of $fc.\n";
print "If you want to change this, change the script!\n";

close(OUT);

exit;
