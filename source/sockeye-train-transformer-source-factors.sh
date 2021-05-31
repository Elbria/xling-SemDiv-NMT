#!/bin/bash
# Weijia

### Parameters
# gpus=1,2,4
model_args=""

echo $train_tgt
# Training
gpu_ids=$(echo $gpus | sed "s/,/ /g")
if [ ! -d $model_dir ]; then
		echo "Start training..."
    		python3 -m sockeye.train \
        		-s $train_src \
        		-t $train_tgt \
 			-o $model_dir \
        		-vs $dev_src \
        		-vt $dev_tgt \
			-sf $train_src_factors \
			-vsf $dev_src_factors \
			--source-factors-num-embed 8 \
                        --source-factors-combine concat \
        		$model_args \
        		--weight-tying-type='trg_softmax' \
        		--num-words 50000:50000 \
        		--label-smoothing 0.1 \
        		--encoder transformer \
        		--decoder transformer \
        		--num-layers 6 \
        		--transformer-attention-heads 8 \
        		--transformer-model-size 504 \
        		--num-embed 504 \
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

