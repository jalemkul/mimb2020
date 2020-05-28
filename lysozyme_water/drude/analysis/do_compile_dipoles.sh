#!/bin/bash

# Requires an installation of GROMACS to use gmx analyze

vacout="dipole_vac_vs_residue.dat"
solout="dipole_vs_residue.dat"
diffout="dipole_diff_vs_residue.dat"
touch $diffout

for (( i=2; i<129; i++ ))
do
    # account for "missing" Gly files
    if [ -e dipole.${i}.vac.sc.dat ];
    then
        # averages from solution
        ln -s dipole.${i}.sc.dat tmp.xvg
        gmx analyze -f tmp.xvg -quiet &>tmp.out
        avg=`grep "SS1" tmp.out | awk '{print $2}'`
        stdev=`grep "SS1" tmp.out | awk '{print $3}'`
        echo "$i $avg $stdev" >> $solout
        rm tmp.out tmp.xvg

        # averages in vacuo
        ln -s dipole.${i}.vac.sc.dat tmp.xvg
        gmx analyze -f tmp.xvg -quiet &>tmp.out
        avg=`grep "SS1" tmp.out | awk '{print $2}'`
        stdev=`grep "SS1" tmp.out | awk '{print $3}'`
        echo "$i $avg $stdev" >> $vacout
        rm tmp.out tmp.xvg

        # average differences
        perl subtract_two_files.pl dipole.${i}.sc.dat dipole.${i}.vac.sc.dat
        mv diff.dat diff_dipole.${i}.sc.dat
        ln -s diff_dipole.${i}.sc.dat tmp.xvg
        gmx analyze -f tmp.xvg -quiet &>tmp.out
        avg=`grep "SS1" tmp.out | awk '{print $2}'`
        stdev=`grep "SS1" tmp.out | awk '{print $3}'`
        echo "$i $avg $stdev" >> $diffout
        rm tmp.out tmp.xvg
    fi
done

# compute enhancement relative to gas-phase values
perl divide_two_files.pl dipole_diff_vs_residue.dat dipole_vac_vs_residue.dat
mv dividend.dat dipole_enhancement_vs_residue.dat
