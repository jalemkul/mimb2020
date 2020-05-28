#!/usr/bin/python

from simtk.openmm import *
from simtk.openmm.app import * 
from simtk.unit import *
from sys import stdout, exit, stderr

jobname='walp23_popc.drude'

prev=0
curr=prev+1
last=curr+10

psf = CharmmPsfFile(jobname+'.xplor.psf')
# equilibrated structure
crd = PDBFile(jobname+'.'+str(prev)+'.pdb')

# box after equil - used for setup, exact value used for MD read from .rst file below 
x=6.26328*nanometer
y=x
z=7.58639*nanometer
psf.setBox(x,y,z)

params = CharmmParameterSet('toppar_drude/toppar_drude_master_protein_2019g.str', 'toppar_drude/toppar_drude_lipid_2017c.str')

system = psf.createSystem(params, nonbondedMethod=PME, nonbondedCutoff=1.2*nanometer, switchDistance=1.0*nanometer, ewaldErrorTolerance = 0.0001, constraints=HBonds)

nbforce = [system.getForce(i) for i in range(system.getNumForces()) if isinstance(system.getForce(i), NonbondedForce)][0]
nbforce.setNonbondedMethod(NonbondedForce.PME)
nbforce.setEwaldErrorTolerance(0.0001)
nbforce.setCutoffDistance(1.2*nanometer)
nbforce.setUseSwitchingFunction(True)
nbforce.setSwitchingDistance(1.0*nanometer)

# not every system has NBFIX terms, so check 
cstnb = [system.getForce(i) for i in range(system.getNumForces()) if isinstance(system.getForce(i), CustomNonbondedForce)]
if cstnb:
    nbfix = cstnb[0]
    nbfix.setNonbondedMethod(CustomNonbondedForce.CutoffPeriodic)
    nbfix.setCutoffDistance(1.2*nanometer)
    nbfix.setUseSwitchingFunction(True)
    nbfix.setSwitchingDistance(1.0*nanometer)

system.addForce(MonteCarloMembraneBarostat(1*bar, 0*bar*nanometer, 298*kelvin, MonteCarloMembraneBarostat.XYIsotropic, MonteCarloMembraneBarostat.ZFree))

integrator = DrudeLangevinIntegrator(298*kelvin, 5/picosecond, 1*kelvin, 20/picosecond, 0.001*picoseconds)
integrator.setMaxDrudeDistance(0.02) # Drude Hardwall
simulation = Simulation(psf.topology, system, integrator)
simulation.context.setPositions(crd.positions)
simulation.context.computeVirtualSites()

# print out energy and forces
state=simulation.context.getState(getPositions=True, getForces=True, getEnergy=True)
print state.getPotentialEnergy().value_in_unit(kilocalories_per_mole)

# start from the equilibrated positions and velocities
with open(jobname+'.'+str(prev)+'.rst', 'r') as f:
	 simulation.context.setState(XmlSerializer.deserialize(f.read()))

nsavcrd=10000	# report every 10 ps
nstep=10000000	# simulate for 10 ns in each interval
nprint=10000	# report every 10 ps 

# run 100 ns at a time 
for ii in range(curr,last):
	dcd=DCDReporter(jobname+'.'+str(ii)+'.dcd', nsavcrd)
	firstdcdstep = ii*nstep + nsavcrd
	dcd._dcd = DCDFile(dcd._out, simulation.topology, simulation.integrator.getStepSize(), firstdcdstep, nsavcrd) # charmm doesn't like first step to be 0
	simulation.reporters.append(dcd)
	simulation.reporters.append(StateDataReporter(jobname+'.'+str(ii)+'.out', nprint, step=True, kineticEnergy=True, potentialEnergy=True, totalEnergy=True, temperature=True, volume=True, speed=True)) 
	simulation.step(nstep)
	simulation.reporters.pop()
	simulation.reporters.pop()

	# write restart file
	state = simulation.context.getState( getPositions=True, getVelocities=True )
	with open(jobname+'.'+str(ii)+'.rst', 'w') as f:
		f.write(XmlSerializer.serialize(state))

