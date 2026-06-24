#!/bin/bash
#PBS -N ESOE7045
#PBS -l walltime=00:05:00
#PBS -l select=1:ncpus=3:mpiprocs=3
export FI_PROVIDER=tcp
cd $PBS_O_WORKDIR
usecpus=`cat $PBS_NODEFILE |wc -l`
module use /opt/intel/oneapi/modulefiles
module load compiler/latest mkl/latest mpi/latest icc/latest compiler-rt/latest
program=./main.o
mpiexec.hydra -f $PBS_NODEFILE -n $usecpus -ppn 1 $program input.txt 10 1

