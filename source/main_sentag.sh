#!/bin/bash

# Eleftheria

set -e

#child_dir=`dirname $0`/..
#root_dir=$child_dir/..

# ABSOLUTE PATHS FOR SLURM SCHEDULING
root_dir=/fs/clip-xling/projects/semdiv/xling-SemDiv
export child_dir=$root_dir/xling-SemDiv-impact-NMT
scripts_dir=$child_dir/source


source $scripts_dir/parameters.sh
date;
factor_loss_weight=1
 
#Choose configuration
#training_folder=factorized_${factor_loss_weight}w
training_folder=sentence_tag

echo 'Training configuration set: ' $training_folder
suffix=.base.heuristic

dev_src=$mt_dir/dev/$src.tok.tc.bpe$suffix.SENTAG
dev_tgt=$mt_dir/dev/$tgt.tok.tc.bpe$suffix
dev_src_factors=$mt_dir/dev/$src.tok.tc.bpe${suffix}.TAGS
dev_tgt_factors=$mt_dir/dev/$tgt.tok.tc.bpe${suffix}.TAGS

train_src=$divergences_dir-base.heuristic.BPE.SENTAG.$src
train_tgt=$divergences_dir-base.heuristic.BPE.$tgt
train_src_factors=$divergences_dir-base.heuristic.TAGS.$src
train_tgt_factors=$divergences_dir-base.heuristic.TAGS.$tgt

label_smoothing=1
if [[ $label_smoothing == 1 ]]; then
	exp_dir=$exp_main_dir/$training_folder
else
        exp_dir=$exp_main_dir/$training_folder-no-lsmoothing
fi;

echo $train_src

mkdir -p $exp_dir

export label_smoothing
export factor_weight_loss
run_n=1
for i in $(seq 1 $run_n); do
	seed=$i
	model_dir=$exp_dir/transformer-model-$i
        . $scripts_dir/sockeye-train-transformer.sh
	#. $scripts_dir/sockeye-train-transformer-factors-concat.sh
done;
date;
