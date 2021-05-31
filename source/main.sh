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
while getopts "d:p:l" opt; do
	case $opt in
	d)
		divergence=$OPTARG ;;
	p)
		percentage=$OPTARG ;;
	i)
		label_smoothing=$OPTARG
		iterations=2 ;;
	e)
		echo "Usage: main.sh"
		echo "-d divergence type (e.g., equivalents, lexical_substitution, phrace_replacement, subtree_deletion)"
		echo "-p percentage of corpus infused with divergences (e.g., 10, 20, 50, 70, 100)"
		echo "-i intensity range of infused divergences (e.g., None, 0-5, 5-10, 10-15, 15-100)"
		exit 0 ;;
    \?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1 ;;
    :)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1 ;;
	esac
done

export label_smoothing 
#Choose configuration
if [[ $divergence == equivalents ]]; then
    training_folder=equivalents
    suffix=
elif [[ $divergence == all ]]; then
    training_folder=wikimatrix_baseline
    suffix=.base
elif [[ $divergence == heuristic ]]; then
    training_folder=heuristic_based
    suffix=.base.heuristic
elif [[ $divergence == equivalize_best_hypothesis ]]; then
    training_folder=equivalize_best_hypothesis
    suffix=
else
    training_folder=$divergence-$percentage
    suffix=
fi;

echo 'Training configuration: '$training_folder
training_dir=$mt_dir/$training_folder
train_src=$training_dir/$src.tok.tc.bpe
train_tgt=$training_dir/$tgt.tok.tc.bpe
dev_src=$mt_dir/dev/$src.tok.tc.bpe$suffix
dev_tgt=$mt_dir/dev/$tgt.tok.tc.bpe$suffix
label_smoothing=1
if [[ $label_smoothing == 1 ]]; then
	exp_dir=$exp_main_dir/$training_folder
else
        exp_dir=$exp_main_dir/$training_folder-no-lsmoothing
fi;

echo $train_src

mkdir -p $exp_dir

for i in $(seq 1 $run_n); do
	seed=$i
	if [[ $transformer == True ]]; then
	    if [[ $laser == True ]]; then
		    model_dir=$exp_dir/transformer-laser-model-$i
		    . $scripts_dir/sockeye-train-transformer-laser-params.sh
		else
		    model_dir=$exp_dir/transformer-model-$i
		    . $scripts_dir/sockeye-train-transformer.sh
		fi;
	else
		model_dir=$exp_dir/rnn-model-$i
		. $scripts_dir/sockeye-train-rnn.sh
	fi;
done;
date;
