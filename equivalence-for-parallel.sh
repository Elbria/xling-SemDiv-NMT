#!/usr/bin/env bash

#############################################################################
#                                                                           #
#                                                                           #
#              Beyond Noise: Mitigating the Impact of Fine-grained          #
#              Semantic Divergences on Neural Machine Translation           #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 4  ====                               #
#                                                                           #
#          Prepare equivalent data for synthetic divergences                #
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

# ==> Step 1: Create aligner configuration
aligner_configuration=$scripts_dir/aligner.en-${non_en}-equivalents.conf
if [ ! -f "$software_dir/berkeleyaligner/aligner.en-${non_en}-equivalents.conf" ]; then
    echo '> Create aligner configuration for equivalents'
    cd $root_dir
    python $scripts_dir/aligner_configuration.py \
                                      --input-corpus wikimatrix-equivalence-en-$non_en/wikimatrix-en-${non_en} \
                                      --output-corpus output-equivalence. \
                                      --src en \
                                      --tgt $non_en
    mv aligner.en-${non_en}.conf $software_dir/berkeleyaligner/aligner.en-${non_en}-equivalents.conf
    echo '> done'
fi;

# ==> Step 2: Align equivalent sentences of Wikimatrix data
wikimatrix_eq=$child_data_dir/equivalence-pairs
aligned_wikimatrix_eq=${wikimatrix_eq}.align
berkeley_dir=$software_dir/berkeleyaligner
if [ ! -f "$child_data_dir/equivalence-pairs-plus-align" ]; then
    echo '> Align equivalents wikimatrix data using unsupervised Berkeley aligner'
    cd $berkeley_dir

    # Prepare training data
    mkdir -p wikimatrix-equivalence-en-$non_en
    cut -f1 $wikimatrix_eq > wikimatrix-equivalence-en-$non_en/wikimatrix-en-${non_en}.en
    cut -f2 $wikimatrix_eq > wikimatrix-equivalence-en-$non_en/wikimatrix-en-${non_en}.$non_en

    export CONF=aligner.en-${non_en}-equivalents.conf
    bash align $CONF

    cp output-equivalence.en-$non_en/training.align wikimatrix-equivalence-en-$non_en/wikimatrix-en-${non_en}.align
    paste $child_data_dir/equivalence-pairs wikimatrix-equivalence-en-$non_en/wikimatrix-en-${non_en}.align > \
          $child_data_dir/equivalence-pairs-plus-align
    cd $root_dir
fi;
exit
# ==> Step 3: Prepare equivalent data for parallelization
synthetic_dir=$child_dir/synthetic/en-$non_en
per_split_sents=10000
mkdir -p $synthetic_dir

if [ ! -f "$synthetic_dir/equivalence-pairs-" ]; then

   cd $synthetic_dir

   split -l $per_split_sents -d -a 2 equivalence-pairs-plus-align div-split-  
fi;
