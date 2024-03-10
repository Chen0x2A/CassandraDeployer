#!/bin/bash

source ~/.bash_profile
# Get a list of files from $HOME/Cassandra/hostlist and save it into an array
hostlist=($(ls $HOME/Cassandra/hostlist | sed 's/\.txt//'))

rm -f $HOME/Cassandra/finishloader.flag
# Use a for loop to iterate through the array, executing in the order of file names in hostlist, ensuring the first node (seed node) starts first
for i in {0..4}; do
    host=${hostlist[$i]}
    sbatch --nodes=1 --ntasks=1 --cpus-per-task=4 --nodelist=${host} --mem=32G --time=20:00:00 -p long --output=/home/Cassandra/${host}.txt ~/Cassandra/start.sh
done

