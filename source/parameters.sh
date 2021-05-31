#!/bin/bash

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

reverse=True

export mt_dir=
export divergences_dir=
export exp_main_dir=
mkdir -p $exp_main_dir

## pipeline training parameters
export src_max_len=80
export tgt_max_len=80

gpus=0
proc_per_gpu=1
ensemble=False
transformer=True
laser=False

## pipeline parameters
avg_metric_list="perplexity bleu"
avg_n_list="1 4 8"
if [[ $ensemble == True ]]; then
	export run_n=3
else
	export run_n=1
fi;


