#!/usr/bin/env bash

#############################################################################
#                                                                           #
#                                                                           #
#              Beyond Noise: Mitigating the Impact of Fine-grained          #
#              Semantic Divergences on Neural Machine Translation           #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 3a  ====                              #
#                                                                           #
#                  Prepare divergent data for token tags                    #
#                                                                           #
#                                                                           #
#############################################################################

# ==== Set variables
if [ $1 = 'en' ]; then
    non_en=$2
else
    non_en=$1
fi

source divergentmBERT_parameters.sh

software_dir=$root_dir/software
moses_dir=$software_dir/moses-scripts/tokenizer

# ==> Step 5: Create input file for multi divergentmBERT (Huggingface format)
huggingface_dir=$child_dir/wikimatrix_for_huggingface/$1-$2
per_split_sents=500000
mkdir -p $huggingface_dir

if [ ! -f "$huggingface_dir/divergence-pairs" ]; then

   cd $huggingface_dir
   cp $child_data_dir/wikimatrix/wikimatrix-$1-$2-divergence divergence-pairs

   split -l $per_split_sents -d -a 1 divergence-pairs div-split-  

   for i in div-split-* ; do
      
       echo "$i"
       lines=$(wc -l < "$i")
       split_dir=$huggingface_dir/wikimatrix-"$i"
       mkdir -p $split_dir
       mv "$i" $split_dir
       cd $split_dir
       
       # Pseudo file
       huggingface_file=$split_dir/test.tsv
       yes "0" | head -n $lines > pseudo_lbl
       seq $lines > ids
       
       echo "#pseudo-label\t#1-pseudo-ID\t#2-pseudo-ID\t#english_sentence\t#french_sentence" \
             > $huggingface_file
       paste pseudo_lbl ids ids "$i" >> $huggingface_file
       rm ids pseudo_lbl
        
       cd $huggingface_dir
    done;
fi;
