#!/bin/bash

### Parameters
#gpus=0,1
model_args=""
#--weight-tying-type='trg_softmax' \
echo $train_tgt
# Training
gpu_ids=$(echo $gpus | sed "s/,/ /g")
#gpu_ids=0,1
if [ ! -d $model_dir ]; then
		echo "Start training..."
    		python3 -m sockeye.train \
        		-s $train_src \
        		-t $train_tgt \
 			-o $model_dir \
        		-vs $dev_src \
        		-vt $dev_tgt \
			-sf $train_src_factors \
			-tf $train_tgt_factors \
			-vtf $dev_tgt_factors \
			-vsf $dev_src_factors \
                        --source-factors-num-embed 8 \
                        --source-factors-combine concat \
                        --target-factors-num-embed 8 \
                        --target-factors-combine concat \
			--weight-tying-type none \
			--target-factors-weight 1 \
        		$model_args \
			--source-vocab $train_src_vocab \
			--target-vocab $train_tgt_vocab \
        		--num-words 5000:5000 \
        		--label-smoothing 0.1 \
        		--encoder transformer \
        		--decoder transformer \
        		--num-layers 6 \
        		--transformer-attention-heads 8 \
        		--transformer-model-size 504:512 \
        		--num-embed 504:504 \
        		--transformer-feed-forward-num-hidden 2048 \
        		--transformer-preprocess n \
        		--transformer-postprocess dr \
        		--gradient-clipping-type none \
        		--transformer-dropout-attention 0.1 \
        		--transformer-dropout-act 0.1 \
        		--transformer-dropout-prepost 0.1 \
        		--max-seq-len $src_max_len:$tgt_max_len \
        		--batch-type word \
        		--batch-size 2048 \
        		--min-num-epochs 3 \
        		--initial-learning-rate .0002 \
        		--learning-rate-reduce-factor .7 \
       			--learning-rate-reduce-num-not-improved 4 \
        		--checkpoint-interval 1000 \
        		--keep-last-params 30 \
        		--max-num-checkpoint-not-improved 20 \
        		--decode-and-evaluate 1000 \
        		--seed $seed \
        		--disable-device-locking \
        		--device-ids $gpu_ids \
        		$model_args
fi;

