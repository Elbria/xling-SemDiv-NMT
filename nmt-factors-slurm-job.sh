#!/bin/bash

#SBATCH --job-name=sourcefactorsNMT
#SBATCH --time=1-00:00:00
#SBATCH --mem=150g
#SBATCH --qos=gpu-medium
##SBATCH --exclude=materialgpu02
#SBATCH --cpus-per-task=6
#SBATCH --gres=gpu:3
#SBATCH --partition=gpu

module load cuda/10.0.130
module load cudnn/v7.5.0

source ~/.bashrc
conda activate semdiv

bash source/main_factors.sh
