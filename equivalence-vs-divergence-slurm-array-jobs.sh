#!/usr/bin/env bash	

#############################################################################
#                                                                           #
#                                                                           #
#              Beyond Noise: Mitigating the Impact of Fine-grained          #
#              Semantic Divergences on Neural Machine Translation           #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 2  ====                               #
#                                                                           #
#             Predictions of equivalence vs. divergence on Wikimatrix       #
#                                                                           #
#                                                                           #
#############################################################################

# This scripts has been configured to run with SLURM job arrays
# for job parallelization on the CLIP cluster
 
#SBATCH --job-name=divergentmBERT
#SBATCH --nodes=1 --ntasks-per-node=1
#SBATCH --time=1-00:00:00
#SBATCH --output=divergentmBERT_%A_%a.out
#SBATCH --error=divergentmBERT_%A_%a.err

#SBATCH --partition=gpu
#SBATCH --gres=gpu:gtx1080ti:1 
#SBATCH --qos=gpu-medium
#SBATCH --exclude=materialgpu00

source ~/.bashrc
conda activate semdiv

##############################################################################

if [ $1 = 'en' ]; then
    non_en=$2
else
    non_en=$1
fi

source divergentmBERT_parameters.sh 
################################################################################

set_=test_synthetic

if [ ! -f $parallel_corpus_dir/split-${SLURM_ARRAY_TASK_ID}.predictions ] ; then

    python $scripts_dir/run_div_margin.py \
           	--node $SLURM_NODELIST \
        	--model_type bert_margin \
        	--model_name_or_path $model \
        	--task_name SemDiv \
        	--do_eval   \
        	--best_checkpoint \
		--split $SLURM_ARRAY_TASK_ID\
        	--evaluation_set $set_ \
        	--data_dir $data_dir/   \
        	--output_dir $output_dir \
        	--synth_data_dir $parallel_corpus_dir/ \
        	--overwrite_cache

    echo '> Save results prediction results'
    mv $output_dir/best-${SLURM_ARRAY_TASK_ID}_test_synthetic_preds_gt.txt $parallel_corpus_dir/split-${SLURM_ARRAY_TASK_ID}.predictions
    echo '> Done'
fi;

# If $3 argument is set to "extract" write no-meaning-difference to file
if [ $3 = 'extract' ]; then
    if [ ! -f $child_data_dir/wikimatrix/wikimatrix-$src-$tgt-equivalence ]; then
        mkdir -p $child_data_dir/wikimatrix
        echo '> Extract no meaning differences'
        python $child_scripts_dir/eq-vs-dv.py \
               --data-dir $child_dir/wikimatrix_for_huggingface/$src-$tgt \
               --batch-mode \
               --split-dir wikimatrix-split \
               --number-batches 2 \
               --output-corpus-prefix $child_data_dir/wikimatrix/wikimatrix-$src-$tgt-
    fi;
fi;
