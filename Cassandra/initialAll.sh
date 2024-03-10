#!/bin/bash

#SBATCH --job-name=initial_Cassandra    
#SBATCH --output=/home/Cassandra/initial_output.txt 
#SBATCH --error=/home/Cassandra/initial_error.txt
#SBATCH --nodes=5
#SBATCH --ntasks=5
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --nodelist=node[27-31]
#SBATCH -p long

rm -rf $HOME/Cassandra/hostlist
chmod +x ~/Cassandra/initial.sh
srun -l ~/Cassandra/initial.sh