#!/usr/bin/env bash

#############################################################################
#                                                                           #
#                                                                           #
#        On the impact of fine-grained cross-lingual semantic divergences   #
#              on Neural Machine Translation                                #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 7  ====                               #
#                                                                           #
#                        Preprocess data for MT                             #
#                                                                           #
#                                                                           #
#############################################################################


# ==== Set variables

subword_vocab_size=5000

# == Nature variables
percentages="10 20 50 70 100"
divergent_types="phrase_replacement subtree_deletion lexical_substitution"

# == Intensity variables
intensity_percentages="50 60"
intensity_ranges="0-5 5-10 10-15 15-100"

# ==== Set directories
root_dir=$PWD
root_software_dir=$root_dir/software
moses_tok=$root_software_dir/moses-scripts/tokenizer
moses_rec=$root_software_dir/moses-scripts/recaser
ted_data=/fs/cliphomes/ebriakou/ted_talks


child_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mt_data_dir=$child_dir/for-MT/$1-$2
scripts_dir=$child_dir/source
wmt_data=$mt_data_dir/wmt-split


echo "Moses steps: a) replace Unicode punctuation
                   b) normalize punctuation
                   c) remove non printing characters
                   d) tokenize"


# Training data

for lang in $1 $2; do

    echo "Preprocess training data for language: "$lang

    # === Semantic equivalents === #

    file=$mt_data_dir/equivalents/$lang
    truecaser_model=$file.tc.model
    bpe_model=$file.tok.tc.bpe.model

    if [[ ! -f "$file.tok" && ! -f "$file.tok.tc" ]]; then
        echo "Preprocess "$file" using Moses scripts"
        cat $file | \
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


    # === Semantic divergences === #
    # ===       Nature         === #

    for per in $percentages; do

        for div in $divergent_types; do

            exp_configuration=$div-$per
            file=$mt_data_dir/$exp_configuration/$lang

            if [[ ! -f "$file.tok" && ! -f "$file.tok.tc" ]]; then
                echo "Preprocess "$file" using Moses scripts"
                cat $file | \
                            $moses_tok/replace-unicode-punctuation.perl | \
                            $moses_tok/normalize-punctuation.perl -l $lang | \
                            $moses_tok/remove-non-printing-char.perl | \
                            $moses_tok/tokenizer.perl -l $lang -no-escape -threads 8 \
                            > $file.tok
                echo "Done"
            fi;

            if [[ ! -f "$file.tok.tc" ]]; then
                echo "Apply truecaser on "$file
                $moses_rec/truecase.perl < $file.tok > $file.tok.tc -model $truecaser_model
                rm $file.tok
            fi;

            if [[ ! -f "$file.tok.tc.bpe" ]]; then
                echo "Apply BPEs"
                python $scripts_dir/apply-sentencepiece.py \
                    --model $bpe_model\
                    --file $file.tok.tc \
                    --output $file.tok.tc.bpe
            fi;
        done
    done

    # === Semantic divergences === #
    # ===      Intensity       === #

    for in_per in $intensity_percentages; do

        for in_ran in $intensity_ranges; do

            exp_configuration=$in_per.perc-$in_ran.intens
            file=$mt_data_dir/intensity/$exp_configuration/$lang

            if [[ ! -f "$file.tok" && ! -f "$file.tok.tc" ]]; then
                echo "Preprocess "$file" using Moses scripts"
                cat $file | \
                            $moses_tok/replace-unicode-punctuation.perl | \
                            $moses_tok/normalize-punctuation.perl -l $lang | \
                            $moses_tok/remove-non-printing-char.perl | \
                            $moses_tok/tokenizer.perl -l $lang -no-escape -threads 8 \
                            > $file.tok
                echo "Done"
            fi;

            if [[ ! -f "$file.tok.tc" ]]; then
                echo "Apply truecaser on "$file
                $moses_rec/truecase.perl < $file.tok > $file.tok.tc -model $truecaser_model
                rm $file.tok
            fi;

            if [[ ! -f "$file.tok.tc.bpe" ]]; then
                echo "Apply BPEs"
                python $scripts_dir/apply-sentencepiece.py \
                    --model $bpe_model\
                    --file $file.tok.tc \
                    --output $file.tok.tc.bpe
            fi;
        done
    done
done

# Preprocess test-dev TED data
for target in dev test; do

    target_dir=$mt_data_dir/$target
    if [ ! -d $target_dir ]; then

        mkdir -p $target_dir

        echo "Detokenize TED data: $target"

        if [ ! -f $ted_data/$1 ]; then

            python $scripts_dir/preprocess-ted.py \
                --src $1 \
                --tgt $2 \
                --data-dir $ted_data/all_talks_$target.tsv \
                --output-dir $target_dir

            cut -f 1 $target_dir/$1-$2 \
                    | $moses_tok/detokenizer.perl -q -l $1 \
                    > $target_dir/$1

            cut -f 2 $target_dir/$1-$2 \
                    | $moses_tok/detokenizer.perl -q -l $2 \
                    > $target_dir/$2

            #rm $target_dir/$1-$2
        fi;

        for lang in $1 $2; do

            tmp=$mt_data_dir/equivalents/$lang
            truecaser_model=$tmp.tc.model
            bpe_model=$tmp.tok.tc.bpe.model

            file=$target_dir/$lang
            if [[ ! -f "$file.tok" && ! -f "$file.tok.tc" ]]; then
                echo "Preprocess "$file" using Moses scripts"
                cat $file | \
                        $moses_tok/replace-unicode-punctuation.perl | \
                        $moses_tok/normalize-punctuation.perl -l $lang | \
                        $moses_tok/remove-non-printing-char.perl | \
                        $moses_tok/tokenizer.perl -l $lang -no-escape -threads 8 \
                        > $file.tok
                echo "Done"
            fi;

            if [[ ! -f "$file.tok.tc" ]]; then
                echo "Apply truecaser on "$file
                $moses_rec/truecase.perl < $file.tok > $file.tok.tc -model $truecaser_model
                rm $file.tok
            fi;

            if [[ ! -f "$file.tok.tc.bpe" ]]; then
                echo "Apply BPEs"
                python $scripts_dir/apply-sentencepiece.py \
                    --model $bpe_model\
                    --file $file.tok.tc \
                    --output $file.tok.tc.bpe
            fi;
        done
    fi;
done

years="2008 2009 2010 2011 2012 2013 2014 2015"
# Preprocess WMT test data
for target in $years; do
    echo 'Proprocess WMT year: '$target
    for lang in $1 $2; do
        file=$wmt_data/$2-$1-$target/original_$2/$lang

        tmp=$mt_data_dir/equivalents/$lang
        truecaser_model=$tmp.tc.model
        bpe_model=$tmp.tok.tc.bpe.model

        if [[ ! -f "$file.tok" && ! -f "$file.tok.tc" ]]; then
            echo "Preprocess "$file" using Moses scripts"
            cat $file | \
                    $moses_tok/replace-unicode-punctuation.perl | \
                    $moses_tok/normalize-punctuation.perl -l $lang | \
                    $moses_tok/remove-non-printing-char.perl | \
                    $moses_tok/tokenizer.perl -l $lang -no-escape -threads 8 \
                    > $file.tok
            echo "Done"
        fi;

        if [[ ! -f "$file.tok.tc" ]]; then
            echo "Apply truecaser on "$file
                $moses_rec/truecase.perl < $file.tok > $file.tok.tc -model $truecaser_model
            rm $file.tok
        fi;

        if [[ ! -f "$file.tok.tc.bpe" ]]; then
            echo "Apply BPEs"
            python $scripts_dir/apply-sentencepiece.py \
                --model $bpe_model\
                --file $file.tok.tc \
                --output $file.tok.tc.bpe
        fi;
        done
done