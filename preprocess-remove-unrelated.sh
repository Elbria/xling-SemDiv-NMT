#!/usr/bin/env bash

#############################################################################
#                                                                           #
#                                                                           #
#              Beyond Noise: Mitigating the Impact of Fine-grained          #
#              Semantic Divergences on Neural Machine Translation           #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 7a  ====                              #
#                                                                           #
#                        Wikimatrix Configurations for training             #
#		on equivalents and fine divergences                         #
#                                                                           #
#                                                                           #
#############################################################################

# Assumption: we have already run divergentmBERT and identified 
# a equivalence versus divergence split!

# ==== Set variables

subword_vocab_size=5000

# ==== Set variables
if [ $1 = 'en' ]; then
    non_en=$2
else
    non_en=$1
fi

# ==== Set directories
root_dir=$PWD
root_software_dir=$root_dir/software
moses_tok=$root_software_dir/moses-scripts/tokenizer
moses_rec=$root_software_dir/moses-scripts/recaser
bicleaner_dir=$root_software_dir/bicleaner/bicleaner
bicleaner_model=bicleaner/bicleaner_models/en-$non_en/en-${non_en}.yaml
ted_data=

child_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mt_data_dir=$child_dir/for-MT/$1-$2/heuristic_based
scripts_dir=$child_dir/source
divergent_data=

mkdir -p $mt_data_dir


# Step 1: Detokenize divergentmBERT output (Note: Bicleaner requires detokenized input text!)
divergent_classes="wikimatrix-$1-$2-divergence wikimatrix-$1-$2-equivalence"

for target in $divergent_classes; do

        file=$divergent_data/$target
        echo 'Detokenize Divergent class: '$target
        
        if [[ ! -f "$file.en" && ! -f "$file.$non_en" ]]; then
            echo '> Extract source-target files for detokenization...'
            cut -f 1 $file > $file.en
            cut -f 2 $file > $file.$non_en
        fi;

        # Detokenize English
	if [[ ! -f "$file.en.detok" && ! -f "$file.detok" ]]; then
	    echo '> Detokenize English side of: '$target
 	    cat $file.en \
               | $moses_tok/detokenizer.perl -q -l en -threads 8 2>/dev/null \
               > $file.en.detok
        fi;

        # Detokenize non-English side
        if [[ ! -f "$file.$non_en.detok" && ! -f "$file.detok" ]]; then
            echo '> Detokenize non-English side of: '$target
            cat $file.$non_en \
               | $moses_tok/detokenizer.perl -q -l $non_en -threads 8 2>/dev/null \
               > $file.$non_en.detok
        fi;

        if [[ ! -f "$file.detok" ]]; then
	    paste $file.en.detok $file.$non_en.detok > $file.detok 
            rm $file.en.detok $file.$non_en.detok 
	fi; 
done;

# Step 2: Run bicleaner on divergences (This step is needed so that we filter out unrelated pairs)
file=$divergent_data/wikimatrix-$1-$2-divergence
if [[ ! -f "$file.detok.bcl" ]]; then
        echo '> Score divergences with pretrained bicleaner model...'
	python $bicleaner_dir/bicleaner_classifier_full.py $file.detok $file.detok.bcl $bicleaner_model --scol 1 --tcol 2
fi;

# Step 3: Extract sentences with Bicleaner score greater or equal to 0.5 as fine-grained divergences
if [[ ! -f "${file}.some-meaning-difference.bicleaner" ]]; then	
      python $scripts_dir/sd-vs-un-bicleaner.py \
		--data-dir-token $child_dir/wikimatrix_for_huggingface/en-$non_en/divergence-pairs.predictions \
		--data-dir-bicleaner $file.detok.bcl \
		--output-corpus-prefix $file
fi;

# Step 4: Combine results for vanilla experiment
vanilla_file=$divergent_data/wikimatrix-$1-$2-vanilla
if [[ ! -f "$vanilla_file.$1" && ! -f "$vanilla_file.$2" ]]; then
      cat $divergent_data/wikimatrix-$1-$2-equivalence.en > ${vanilla_file}.en
      cut -f 1 ${file}-some-difference-bicleaner >> ${vanilla_file}.en
      cat $divergent_data/wikimatrix-$1-$2-equivalence.$non_en > ${vanilla_file}.$non_en
      cut -f 2 ${file}-some-difference-bicleaner >> ${vanilla_file}.$non_en
fi;


# Step 5: Preprocess training data for various experimental settings 
# (a,b,c, have been already implemented in previous steps -- no repetitions)
echo "Moses steps: a) replace Unicode punctuation
                   b) normalize punctuation
                   c) remove non printing characters
                   d) tokenize"

# Step 5a: Extract and detokenize test-dev TED data
for target in dev test; do

    target_dir=$mt_data_dir/data/${target}
    
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
        fi;
    fi;
done

# Step 5b: Train models on equivalents and vanilla configurations
#for config in equivalence vanilla; do
for config in equivalence; do
    for lang in $1 $2; do

        #echo "Preprocess training data for language (equivalents version): "$lang
        #echo "Configuration: "$config

        # This file is already tokenized from previous steps
        input_file=$child_dir/data/wikimatrix/wikimatrix-$1-$2-$config.$lang

        preprocessed_models_dir=$mt_data_dir/preprocessed_models/$config
        preprocessed_data_dir=$mt_data_dir/data/training/$config

        truecaser_model=$preprocessed_models_dir/$lang.tc.model
        bpe_model=$preprocessed_models_dir/$lang.tc.bpe.model

        mkdir -p $preprocessed_models_dir
        mkdir -p $preprocessed_data_dir

        output_file=$preprocessed_data_dir/$lang

        if [[ ! -f "$truecaser_model" ]]; then
            echo "Train truecaser using "$input_file
            $moses_rec/train-truecaser.perl -model $truecaser_model -corpus $input_file
        fi;

        if [[ ! -f "$output_file.tok.tc" ]]; then
            echo "Apply truecaser on training data:"$input_file
            $moses_rec/truecase.perl < $input_file > $output_file.tok.tc -model $truecaser_model
        fi;

        if [[ ! -f "$bpe_model" ]]; then
            echo "Train subword unit model"
            python $scripts_dir/train-sentencepiece.py \
                --input $output_file.tok.tc \
                --model_prefix $preprocessed_models_dir/$lang.tc.bpe \
                --vocab_size $subword_vocab_size \
                --model_type bpe
        fi;

        if [[ ! -f "$output_file.tok.tc.bpe" ]]; then
            echo "Apply BPEs on training data"
            python $scripts_dir/apply-sentencepiece.py \
                --model $bpe_model\
                --file $output_file.tok.tc \
                --output $output_file.tok.tc.bpe
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
done

# Step 5c: Create data for <Sentence Tag> experiment 
for lang in $1 $2; do

    config=sentence_tag
    preprocessed_data_dir=$mt_data_dir/data/training/$config

    if [[ ! -f "$preprocessed_data_dir/$lang.tok.tc.bpe.sentags" ]]; then
        
        echo "Preprocess training data for language (sentence tagging): "$lang
        
        # Calculate number of divergences vs equivalences
        nums_equivalents=$(wc -l < "$mt_data_dir/data/training/equivalence/$lang.tok.tc.bpe")
        num_sentences=$(wc -l < "$mt_data_dir/data/training/vanilla/$lang.tok.tc.bpe") 
        num_divergences="$(($num_sentences-$nums_equivalents))" 
    
        preprocessed_vanilla_dir=$mt_data_dir/data/training/vanilla
        preprocessed_data_dir=$mt_data_dir/data/training/$config
    
        mkdir -p $preprocessed_data_dir
   
        # Equivalences are appended first!
        yes "<EQ>" | head -n $nums_equivalents > $preprocessed_data_dir.tmp
        yes "<DIV>" | head -n $num_divergences >> $preprocessed_data_dir.tmp

        paste -d ' ' $preprocessed_data_dir.tmp $preprocessed_vanilla_dir/$lang.tok.tc.bpe > $preprocessed_data_dir/$lang.tok.tc.bpe.sentags 
        #rm $preprocessed_data_dir.tmp
    fi;

    # Apply Truecaser and BPEs on dev and test data
    for target in dev test; do

        target_dir=$mt_data_dir/data/${target}
        file=$target_dir/$lang.tok.tc.bpe.vanilla
        
        if [[ ! -f "$file.sentags" ]]; then

            echo "Add sentence tags to file: "$file
            num_sentences=$(wc -l < "$file")
            yes "<EQ>" | head -n $num_sentences > $file.tmp
            paste -d ' ' $file.tmp $file > $file.sentags
            rm $file.tmp
        fi;
        
    done
done

# Step 5c: Create data for Factorized experiment (Two factors: [ O D ])
preprocessed_factors2_dir=$mt_data_dir/data/training/factors2
if [[ ! -f "$preprocessed_factors2_dir/factors.en" ]]; then
   
    echo "Create data for Factorized divergneces: [ O D ]"
    preprocessed_vanilla_dir=$mt_data_dir/data/training/vanilla
    preprocessed_equivalents_dir=$mt_data_dir/data/training/equivalence

    mkdir -p $preprocessed_factors2_dir

    python $scripts_dir/token2bpe_factors_convert.py \
        --token-predictions $child_dir/data/wikimatrix/wikimatrix-$1-$2-divergence-some-difference-bicleaner \
        --source-subwords $preprocessed_vanilla_dir/en.tok.tc.bpe \
        --target-subwords $preprocessed_vanilla_dir/${non_en}.tok.tc.bpe \
        --source-subwords-eq $preprocessed_equivalents_dir/en.tok.tc.bpe \
        --target-subwords-eq $preprocessed_equivalents_dir/${non_en}.tok.tc.bpe \
        --output-path $preprocessed_factors2_dir/factors \
        --source-subwords-dev $mt_data_dir/data/dev/en.tok.tc.bpe.vanilla \
        --target-subwords-dev $mt_data_dir/data/dev/${non_en}.tok.tc.bpe.vanilla \
        --source-subwords-test $mt_data_dir/data/test/en.tok.tc.bpe.vanilla \
        --target-subwords-test $mt_data_dir/data/test/${non_en}.tok.tc.bpe.vanilla \
        --tgt $non_en \
        --num-factors 2
fi;

# Step 5d: Create data for Factorized experiment (Two factors: [ E O D ])
preprocessed_factors2_dir=$mt_data_dir/data/training/factors3
if [[ ! -f "$preprocessed_factors3_dir/factors.en" ]]; then

    echo "Create data for Factorized divergences: [ E O D ]"
    preprocessed_vanilla_dir=$mt_data_dir/data/training/vanilla
    preprocessed_equivalents_dir=$mt_data_dir/data/training/equivalence

    mkdir -p $preprocessed_factors2_dir

    python $scripts_dir/token2bpe_factors_convert.py \
        --token-predictions $child_dir/data/wikimatrix/wikimatrix-$1-$2-divergence-some-difference-bicleaner \
        --source-subwords $preprocessed_vanilla_dir/en.tok.tc.bpe \
        --target-subwords $preprocessed_vanilla_dir/${non_en}.tok.tc.bpe \
        --source-subwords-eq $preprocessed_equivalents_dir/en.tok.tc.bpe \
        --target-subwords-eq $preprocessed_equivalents_dir/${non_en}.tok.tc.bpe \
        --output-path $preprocessed_factors2_dir/factors \
        --source-subwords-dev $mt_data_dir/data/dev/en.tok.tc.bpe.vanilla \
        --target-subwords-dev $mt_data_dir/data/dev/${non_en}.tok.tc.bpe.vanilla \
        --source-subwords-test $mt_data_dir/data/test/en.tok.tc.bpe.vanilla \
        --target-subwords-test $mt_data_dir/data/test/${non_en}.tok.tc.bpe.vanilla \
        --tgt $non_en \
        --num-factors 3
fi;
