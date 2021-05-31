#!/usr/bin/env bash

#############################################################################
#                                                                           #
#                                                                           #
#              Beyond Noise: Mitigating the Impact of Fine-grained          #
#              Semantic Divergences on Neural Machine Translation           #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 3b  ====                              #
#                                                                           #
#            Token-level predictions on divergent Wikimatrix data           #
#                                                                           #
#                                                                           #
#############################################################################

# This scripts has been configured to run with SLURM job arrays
# for job parallelization on the CLIP cluster
 
source ~/.bashrc
conda activate semdiv

##############################################################################

if [ $1 = 'en' ]; then
    non_en=$2
else
    non_en=$1
fi;

source divergentmBERT_parameters.sh

################################################################################

set_=test

if [ ! -f $parallel_corpus_dir/div-split-${SLURM_ARRAY_TASK_ID}.predictions ] ; then

    python $scripts_dir/run_div_multi.py \
           	--node $SLURM_NODELIST \
        	--model_type SemDivMulti \
        	--model_name_or_path $model \
        	--task_name SemDiv \
        	--do_eval   \
        	--best_checkpoint \
		--split $SLURM_ARRAY_TASK_ID\
        	--evaluation_set $set_ \
        	--data_dir $data_dir/   \
        	--output_dir $output_dir \
        	--synth_data_dir $parallel_corpus_dir/ \
        	#--overwrite_cache

    echo '> Save results prediction results'
    mv $output_dir/${SLURM_ARRAY_TASK_ID}_test_predictions.txt $parallel_corpus_dir/div-split-${SLURM_ARRAY_TASK_ID}.predictions
    echo '> Done'
fi;

# If $3 argument is set to "extract" write no-meaning-difference to file
if [ $3 = 'extract' ]; then
    if [ ! -f $child_data_dir/wikimatrix/wikimatrix-$src-$tgt-unrelated1 ]; then
        mkdir -p $child_data_dir/wikimatrix
        echo '> Extract unrelated vs some meaning difference'
        python $child_scripts_dir/sd-vs-un.py \
               --data-dir $child_dir/wikimatrix_for_huggingface/$src-$tgt \
               --batch-mode \
               --split-dir wikimatrix-div-split \
               --number-batches 4 \
               --output-corpus-prefix $child_data_dir/wikimatrix/wikimatrix-$src-$tgt-
    fi;
fi;
