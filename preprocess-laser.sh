#!/usr/bin/env bash

#############################################################################
#                                                                           #
#                                                                           #
#        On the impact of fine-grained cross-lingual semantic divergences   #
#              on Neural Machine Translation                                #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 7c  ====                              #
#                                                                           #
#                        Wikimatrix baseline                                #
#                                                                           #
#                                                                           #
#############################################################################


# ==== Set variables

subword_vocab_size=5000


# ==== Set directories
root_dir=$PWD
root_software_dir=$root_dir/software
moses_tok=$root_software_dir/moses-scripts/tokenizer
moses_rec=$root_software_dir/moses-scripts/recaser

config=laser_exclude_noise

child_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mt_data_dir=/fs/clip-scratch/ebriakou/xling_SemDiv_ImpoNMT/for-MT/$1-$2
scripts_dir=$child_dir/source
ted_data=/fs/cliphomes/ebriakou/ted_talks

mkdir -p $mt_data_dir

echo "Moses steps: a) replace Unicode punctuation
                   b) normalize punctuation
                   c) remove non printing characters
                   d) tokenize"

for lang in $1 $2; do

    echo "Preprocess training data for language: "$lang

    # === Wikimatrix (1.04) === #

    input_file=$root_dir/data/wikimatrix/WikiMatrix.en-fr.104.tsv.FILTER_NOISE.$lang
    file_dir=$mt_data_dir/data/training/$config
    mkdir -p $file_dir
    file=$file_dir/$lang
    truecaser_model=$file.tc.model
    bpe_model=$file.tok.tc.bpe.model

    if [[ ! -f "$file.tok" && ! -f "$file.tok.tc" ]]; then
        echo "Preprocess "$file" using Moses scripts"
        cat $input_file | \
                    $moses_tok/replace-unicode-punctuation.perl | \
                    $moses_tok/normalize-punctuation.perl -l $lang | \
                    $moses_tok/remove-non-printing-char.perl | \
                    $moses_tok/tokenizer.perl -l $lang -no-escape -threads 8 \
                    > $file.tok
        echo "Done"
    fi;

    if [[ ! -f "$file.tc.model" ]]; then
        echo "Train truecaser using "$file
        $moses_rec/train-truecaser.perl -model $file.tc.model -corpus $file.tok
    fi;

    if [[ ! -f "$file.tok.tc" ]]; then
        echo "Apply truecaser on "$file
        $moses_rec/truecase.perl < $file.tok > $file.tok.tc -model $file.tc.model
        rm $file.tok
    fi;

    if [[ ! -f "$file.tok.tc.bpe.model" ]]; then
        echo "Train subword unit model"
        python $scripts_dir/train-sentencepiece.py \
                --input $file.tok.tc \
                --model_prefix $file.tok.tc.bpe \
                --vocab_size $subword_vocab_size \
                --model_type bpe
    fi;

    if [[ ! -f "$file.tok.tc.bpe" ]]; then
        echo "Apply BPEs"
        python $scripts_dir/apply-sentencepiece.py \
            --model $file.tok.tc.bpe.model\
            --file $file.tok.tc \
            --output $file.tok.tc.bpe
    fi;

    # Apply Truecaser and BPEs on dev and test data
    for target in dev test khresmoi_query khresmoi_summary wmt14_fr2en; do

        target_dir=$mt_data_dir/data/${target}
        file=$target_dir/$lang

        if [[ ! -f "$file.tok" ]]; then
                echo "Preprocess "$file" using Moses scripts"
                cat $file | \
                        $moses_tok/replace-unicode-punctuation.perl | \
                        $moses_tok/normalize-punctuation.perl -l $lang | \
                        $moses_tok/remove-non-printing-char.perl | \
                        $moses_tok/tokenizer.perl -l $lang -no-escape -threads 8 \
                        > $file.tok
                echo "Done"
        fi;

        if [[ ! -f "$file.tok.tc.$config" ]]; then
                echo "Apply truecaser on "$file
                $moses_rec/truecase.perl < $file.tok > $file.tok.tc.$config -model $truecaser_model
        fi;

        if [[ ! -f "$file.tok.tc.bpe.$config" ]]; then
                echo "Apply BPEs"
                python $scripts_dir/apply-sentencepiece.py \
                    --model $bpe_model\
                    --file $file.tok.tc.$config \
                    --output $file.tok.tc.bpe.$config
        fi;
    done
done
