#!/bin/bash

#SBATCH --job-name=impactEVA
#SBATCH --time=1-00:00:00
#SBATCH --mem=150g
#SBATCH --qos=gpu-medium
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:1
#SBATCH --partition=gpu

module load cuda/10.0.130
module load cudnn/v7.5.0

source ~/.bashrc
conda activate semdiv

d=$1
p=$2

echo 'Divergences: '$d
echo 'Percentage: '$p

scripts_dir=source
beam=5
gpu=0

bash $scripts_dir/sockeye-evaluate-grid.sh -g $gpu -b $beam -d $d -p $p -l 1

exit
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu  -b $beam -d phrase_replacement -p 10 -i 
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d phrase_replacement -p 20 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d phrase_replacement -p 50 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d phrase_replacement -p 70 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d phrase_replacement -p 100 -i


#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d subtree_deletion -p 10 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d subtree_deletion -p 20 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d subtree_deletion -p 50 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d subtree_deletion -p 70 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d subtree_deletion -p 100 -i

exit

#bash $scripts_dir/sockeye-evaluate-grid.sh -g $gpu -b $beam -d equivalents -p -i
#bash $scripts_dir/sockeye-evaluate-grid.sh -g $gpu -b $beam -d all

#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d lexical_substitution -p 10 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d lexical_substitution -p 20 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d lexical_substitution -p 50 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d lexical_substitution -p 70 -i
#bash $scripts_dir/sockeye-evaluate-grid-slurm.sh -g $gpu -b $beam -d lexical_substitution -p 100 -i

#bash $scripts_dir/sockeye-evaluate.sh -d $d -p $p -i $i
