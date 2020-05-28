#!/bin/bash

# Requires an installation of GROMACS to use gmx analyze

# output file
outfile="percent_sasa_vs_residue.dat"
touch $outfile

for (( i=1; i<130; i++ ))
do
    # fix time values from dummy CORREL values
    perl fix_time.pl 1aki_totalsasa_${i}.dat 10 10
    perl fix_time.pl 1aki_partialsasa_${i}.dat 10 10

    # divide the two to get the % exposed
    perl divide_two_files.pl 1aki_partialsasa_${i}_fix.xvg 1aki_totalsasa_${i}_fix.xvg
    mv dividend.dat frac_${i}.xvg

    # collate
    gmx analyze -f frac_${i}.xvg -quiet &> tmp.out
    avg=`grep "SS1" tmp.out | awk '{print $2}'`
    stdev=`grep "SS1" tmp.out | awk '{print $3}'`
    rm tmp.out

    echo "$i $avg $stdev" >> $outfile
done

exit;
