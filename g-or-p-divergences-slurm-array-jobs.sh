#!/usr/bin/env bash

#############################################################################
#                                                                           #
#                                                                           #
#              Beyond Noise: Mitigating the Impact of Fine-grained          #
#              Semantic Divergences on Neural Machine Translation           #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 6  ====                               #
#                                                                           #
#   Lexical substitution divergences (generalization, particularization)    #
#                                                                           #
#                                                                           #
#############################################################################

# This scripts has been configured to run with SLURM job arrays
# for job parallelization on the CLIP cluster

#SBATCH --job-name=synthetic
#SBATCH --nodes=1 --ntasks-per-node=1
#SBATCH --time=1-00:00:00
#SBATCH --output=synthetic_%A_%a.out
#SBATCH --error=synthetic_%A_%a.err

#SBATCH --partition=dpart
#SBATCH --qos=batch

source ~/.bashrc
conda activate semdiv

##############################################################################

if [ $1 = 'en' ]; then
    non_en=$2
else
    non_en=$1
fi

if [ $3 = 'g' ]; then
    process=g
elif [ $3 = 'p' ]; then
    process=p
else
   echo 'Wrong divergence code; abort...'
   exit
fi

# ==== Set directories
source divergentmBERT_parameters.sh

software_dir=$root_dir/software
child_data_dir=$child_dir/synthetic/en-$non_en
scripts_dir=$root_dir/source
seed_file=div-split-$SLURM_ARRAY_TASK_ID
seeds=$child_data_dir/$seed_file

# === Set dependencies
export NLTK_DATA=$data_dir/nltk_data
python -m spacy download 'en_core_web_sm'

echo $'\n> Generate synthetic divergences from seed equivalents'
python $scripts_dir/generate_divergent_data.py \
			--mode $process \
			--data $seeds \
			--output $child_dir/synthetic/en-$non_en \
			--bert_local_cache pretrained_bert \
			--pretrained_bert "bert-base-cased" \
			#--debug

# If $4 argument is set to "merge" combine splits run in parallel
if [ $4 = 'merge' ]; then
    target=$child_data_dir/from_equivalence-pairs-plus-align
    if [ ! -f $child_data_dir/$target/generalization ]; then
        for d in $child_data_dir/from_div-split-* ; do
            cat $d/generalization >> $target/generalization
            cat $d/generalization.span >> $target/generalization.span
            cat $d/particularization >> $target/particularization
            cat $d/particularization.span >> $target/particularization.span
        done;
    fi;
fi;
