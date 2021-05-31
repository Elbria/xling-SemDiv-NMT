#!/bin/bash

# Eleftheria

set -e

#child_dir=`dirname $0`/..
#root_dir=$child_dir/..

# ABSOLUTE PATHS FOR SLURM SCHEDULING
root_dir=/fs/clip-xling/projects/semdiv/xling-SemDiv
export child_dir=$root_dir/xling-SemDiv-impact-NMT
scripts_dir=$child_dir/source
base_path_to_training_data=/fs/clip-scratch/ebriakou/xling_SemDiv_ImpoNMT/for-MT

# Load parameters and paths to data
source $scripts_dir/parameters.sh
date;
while getopts "e:s:t:n:" opt; do
        
	case $opt in 
	e)
		setting=$OPTARG ;;
	s)
		src=$OPTARG ;;
	t)
		tgt=$OPTARG ;;
        n)
                id=$OPTARG ;;
	h)
		echo "Usage: main_grid_acl2021.sh"
		echo "-e experimental setting (e.g., equivalence, vanilla, sentence_tag, factors2, factors3)"
                echo "-s source language"
                echo "-t target language"
		exit 0 ;;
	esac
done

# Non English language code
if [ $src = 'en' ]; then
    non_en=$tgt
else
    non_en=$src
fi

id_=-$id
id_=
mt_dir=$base_path_to_training_data/en-$non_en/data/training
mt_dev_dir=$base_path_to_training_data/en-$non_en/data/dev
#Choose configuration
if [[ $setting == equivalence ]]; then
    
    train_src=$mt_dir/equivalence/$src.tok.tc.bpe
    train_tgt=$mt_dir/equivalence/$tgt.tok.tc.bpe
    dev_src=$mt_dev_dir/$src.tok.tc.bpe.equivalence
    dev_tgt=$mt_dev_dir/$tgt.tok.tc.bpe.equivalence
    train_src_vocab=$mt_dir/equivalence/$src.tc.bpe.vocab.json
    train_tgt_vocab=$mt_dir/equivalence/$tgt.tc.bpe.vocab.json

elif [[ $setting == vanilla ]]; then

    train_src=$mt_dir/vanilla$id_/$src.tok.tc.bpe
    train_tgt=$mt_dir/vanilla$id_/$tgt.tok.tc.bpe
    dev_src=$mt_dev_dir/$src.tok.tc.bpe.vanilla${id_}
    dev_tgt=$mt_dev_dir/$tgt.tok.tc.bpe.vanilla${id_}
    train_src_vocab=$mt_dir/vanilla${id_}/$src.tc.bpe.vocab.json
    train_tgt_vocab=$mt_dir/vanilla${id_}/$tgt.tc.bpe.vocab.json

elif [[ $setting == vanilla_half ]]; then
    upsample=_half
    train_src=$mt_dir/vanilla$upsample/$src.tok.tc.bpe
    train_tgt=$mt_dir/vanilla$upsample/$tgt.tok.tc.bpe
    dev_src=$mt_dev_dir/$src.tok.tc.bpe.vanilla
    dev_tgt=$mt_dev_dir/$tgt.tok.tc.bpe.vanilla
    train_src_vocab=$mt_dir/vanilla/$src.tc.bpe.vocab.json
    train_tgt_vocab=$mt_dir/vanilla/$tgt.tc.bpe.vocab.json

elif [[ $setting == laser ]]; then

    train_src=$mt_dir/laser/$src.tok.tc.bpe
    train_tgt=$mt_dir/laser/$tgt.tok.tc.bpe
    dev_src=$mt_dev_dir/$src.tok.tc.bpe.laser
    dev_tgt=$mt_dev_dir/$tgt.tok.tc.bpe.laser
    train_src_vocab=$mt_dir/laser/$src.tc.bpe.vocab.json
    train_tgt_vocab=$mt_dir/laser/$tgt.tc.bpe.vocab.json

elif [[ $setting == laser_exclude_noise ]]; then

    train_src=$mt_dir/laser_exclude_noise/$src.tok.tc.bpe
    train_tgt=$mt_dir/laser_exclude_noise/$tgt.tok.tc.bpe
    dev_src=$mt_dev_dir/$src.tok.tc.bpe.laser_exclude_noise
    dev_tgt=$mt_dev_dir/$tgt.tok.tc.bpe.laser_exclude_noise
    train_src_vocab=$mt_dir/laser_exclude_noise/$src.tc.bpe.vocab.json
    train_tgt_vocab=$mt_dir/laser_exclude_noise/$tgt.tc.bpe.vocab.json

elif [[ $setting == laser_exclude_length ]]; then

    train_src=$mt_dir/laser_exclude_length/$src.tok.tc.bpe
    train_tgt=$mt_dir/laser_exclude_length/$tgt.tok.tc.bpe
    dev_src=$mt_dev_dir/$src.tok.tc.bpe.laser_exclude_length
    dev_tgt=$mt_dev_dir/$tgt.tok.tc.bpe.laser_exclude_length
    train_src_vocab=$mt_dir/laser_exclude_length/$src.tc.bpe.vocab.json
    train_tgt_vocab=$mt_dir/laser_exclude_length/$tgt.tc.bpe.vocab.json
elif [[ $setting == sentence_tag ]]; then

    train_src=$mt_dir/sentence_tag${id_}/$src.tok.tc.bpe.sentags
    train_tgt=$mt_dir/vanilla${id_}/$tgt.tok.tc.bpe
    dev_src=$mt_dev_dir/$src.tok.tc.bpe.vanilla${id_}.sentags
    dev_tgt=$mt_dev_dir/$tgt.tok.tc.bpe.vanilla${id_}
    train_src_vocab=$mt_dir/sentence_tag${id_}/$src.tc.bpe.vocab.json
    train_tgt_vocab=$mt_dir/sentence_tag${id_}/$tgt.tc.bpe.vocab.json

elif [[ $setting == factors3_upsample ]]; then

    train_src=$mt_dir/vanilla_upsample/$src.tok.tc.bpe
    train_tgt=$mt_dir/vanilla_upsample/$tgt.tok.tc.bpe
    dev_src=$mt_dev_dir/$src.tok.tc.bpe.vanilla
    dev_tgt=$mt_dev_dir/$tgt.tok.tc.bpe.vanilla
    train_src_vocab=$mt_dir/vanilla/$src.tc.bpe.vocab.json
    train_tgt_vocab=$mt_dir/vanilla/$tgt.tc.bpe.vocab.json 
    train_src_factors=$mt_dir/factors3_upsample/factors.$src
    train_tgt_factors=$mt_dir/factors3_upsample/factors.$tgt
    dev_src_factors=$mt_dev_dir/$src.tok.tc.bpe.vanilla.factors.3
    dev_tgt_factors=$mt_dev_dir/$tgt.tok.tc.bpe.vanilla.factors.3   

else

    train_src=$mt_dir/vanilla${id_}/$src.tok.tc.bpe
    train_tgt=$mt_dir/vanilla${id_}/$tgt.tok.tc.bpe
    dev_src=$mt_dev_dir/$src.tok.tc.bpe.vanilla${id_}
    dev_tgt=$mt_dev_dir/$tgt.tok.tc.bpe.vanilla${id_}
    train_src_vocab=$mt_dir/vanilla${id_}/$src.tc.bpe.vocab.json
    train_tgt_vocab=$mt_dir/vanilla${id_}/$tgt.tc.bpe.vocab.json

    if [[ $setting == factors2 ]]; then
         train_src_factors=$mt_dir/factors2${id_}/factors.$src
         train_tgt_factors=$mt_dir/factors2${id_}/factors.$tgt
         dev_src_factors=$mt_dev_dir/$src.tok.tc.bpe.vanilla${id_}.factors.2
         dev_tgt_factors=$mt_dev_dir/$tgt.tok.tc.bpe.vanilla${id_}.factors.2
    else
         train_src_factors=$mt_dir/factors3${id_}/factors.$src
         train_tgt_factors=$mt_dir/factors3${id_}/factors.$tgt
         dev_src_factors=$mt_dev_dir/$src.tok.tc.bpe.vanilla${id_}.factors.3
         dev_tgt_factors=$mt_dev_dir/$tgt.tok.tc.bpe.vanilla${id_}.factors.3
    fi;
fi;

#echo $train_src
#echo $train_tgt
#echo $dev_src
#echo $dev_tgt

#echo $train_src_factors
#echo $train_tgt_factors
#echo $dev_src_factors
#echo $dev_tgt_factors
#exit

exp_dir=$exp_main_dir/$src-2-$tgt/${setting}${id_}
#exp_dir=$exp_main_dir/$src-2-$tgt/${setting}
mkdir -p $exp_dir
run_n=3
for i in $(seq 1 $run_n); do
	seed=$i
        model_dir=$exp_dir/model-$i
	if [[ $setting == factors2 ]] || [[ $setting == factors3 ]]; then
           . $scripts_dir/sockeye-train-transformer-factors-concat.sh
        else
           . $scripts_dir/sockeye-train-transformer.sh
	fi
done;

date;
