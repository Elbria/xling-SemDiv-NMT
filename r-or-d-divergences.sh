#!/usr/bin/env bash

#############################################################################
#                                                                           #
#                                                                           #
#              Beyond Noise: Mitigating the Impact of Fine-grained          #
#              Semantic Divergences on Neural Machine Translation           #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 5  ====                               #
#                                                                           #
#         Create Subtree Deletion & Phrase Replacement divergences          #
#                                                                           #
#                                                                           #
#############################################################################


if [ $1 = 'en' ]; then
    non_en=$2
else
    non_en=$1
fi

# ==== Set directories
source divergentmBERT_parameters.sh

software_dir=$root_dir/software
child_data_dir=$child_dir/synthetic/en-$non_en
scripts_dir=$root_dir/source
seed_file=equivalence-pairs-plus-align
seeds=$child_data_dir/$seed_file
process=$3

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
			--debug

