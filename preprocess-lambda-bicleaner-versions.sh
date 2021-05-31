#!/usr/bin/env bash

#############################################################################
#                                                                           #
#                                                                           #
#              Beyond Noise: Mitigating the Impact of Fine-grained          #
#              Semantic Divergences on Neural Machine Translation           #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 7b  ====                              #
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
bicleaner_model=$bicleaner_dir/bicleaner_models/en-$non_en/en-${non_en}.yaml
ted_data=     

child_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mt_data_dir=/fs/clip-scratch/ebriakou/xling_SemDiv_ImpoNMT/for-MT/$1-$2
scripts_dir=$child_dir/source
divergent_data=

mkdir -p $mt_data_dir


file=$divergent_data/wikimatrix-$1-$2-divergence
thresholds="5"

for threshold in $thresholds; do

	# Step 3: Extract sentences with Bicleaner score greater or equal to 0.5 as fine-grained divergences
	if [[ ! -f "${file}.some-meaning-difference-bicleaner-${threshold}" ]]; then	
      		python $scripts_dir/sd-vs-un-bicleaner.py \
			--data-dir-token $child_dir/wikimatrix_for_huggingface/en-$non_en/divergence-pairs.predictions \
			--data-dir-bicleaner $file.detok.bcl \
			--output-corpus-prefix $file \
			--bicleaner-threshold $threshold 
	fi;

	# Step 4: Combine results for vanilla experiment
	vanilla_file=$divergent_data/wikimatrix-$1-$2-vanilla-${threshold}
	if [[ ! -f "$vanilla_file.$1" && ! -f "$vanilla_file.$2" ]]; then
      		cat $divergent_data/wikimatrix-$1-$2-equivalence.en > ${vanilla_file}.en
      		cut -f 1 ${file}-some-difference-bicleaner-$threshold >> ${vanilla_file}.en
      		cat $divergent_data/wikimatrix-$1-$2-equivalence.$non_en > ${vanilla_file}.$non_en
      		cut -f 2 ${file}-some-difference-bicleaner-$threshold >> ${vanilla_file}.$non_en
	fi;


	# Step 5: Preprocess training data for various experimental settings 
	# (a,b,c, have been already implemented in previous steps -- no repetitions)
	echo "Moses steps: a) replace Unicode punctuation
                   	   b) normalize punctuation
                   	   c) remove non printing characters
                   	   d) tokenize"
    	config=vanilla-$threshold
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
       		for target in dev test emea khresmoi_query khresmoi_summary wmt14_fr2en; do

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

	# Step 5c: Create data for <Sentence Tag> experiment 
	for lang in $1 $2; do

    		config=sentence_tag-$threshold
    		preprocessed_data_dir=$mt_data_dir/data/training/$config

    		if [[ ! -f "$preprocessed_data_dir/$lang.tok.tc.bpe.sentags" ]]; then
        
        		echo "Preprocess training data for language (sentence tagging): "$lang
        
        		# Calculate number of divergences vs equivalences
        		nums_equivalents=$(wc -l < "$mt_data_dir/data/training/equivalence/$lang.tok.tc.bpe")
        		num_sentences=$(wc -l < "$mt_data_dir/data/training/vanilla-$threshold/$lang.tok.tc.bpe") 
        		num_divergences="$(($num_sentences-$nums_equivalents))" 
    
        		preprocessed_vanilla_dir=$mt_data_dir/data/training/vanilla-$threshold
        		preprocessed_data_dir=$mt_data_dir/data/training/$config
    
        		mkdir -p $preprocessed_data_dir
   
        		# Equivalences are appended first!
        		yes "<EQ>" | head -n $nums_equivalents > $preprocessed_data_dir.tmp
        		yes "<DIV>" | head -n $num_divergences >> $preprocessed_data_dir.tmp

        		paste -d ' ' $preprocessed_data_dir.tmp $preprocessed_vanilla_dir/$lang.tok.tc.bpe > $preprocessed_data_dir/$lang.tok.tc.bpe.sentags 
        		#rm $preprocessed_data_dir.tmp
    		fi;

    		# Apply Truecaser and BPEs on dev and test data
    		for target in dev test emea; do

        		target_dir=$mt_data_dir/data/${target}
        		file=$target_dir/$lang.tok.tc.bpe.vanilla-$threshold
        
        		if [[ ! -f "$file.sentags" ]]; then

            			echo "Add sentence tags to file: "$file
            			num_sentences=$(wc -l < "$file")
            			yes "<EQ>" | head -n $num_sentences > $file.tmp
            			paste -d ' ' $file.tmp $file > $file.sentags
            			rm $file.tmp
        		fi;
        
    		done
	done
        subfile=wmt14_fr2en
        subfile2=khresmoi_summary
	# Step 5d: Create data for Factorized experiment (Two factors: [ E O D ])
	preprocessed_factors3_dir=$mt_data_dir/data/training/factors3-$threshold
	#if [[ ! -f "$preprocessed_factors3_dir/factors.en" ]]; then

    		echo "Create data for Factorized divergences: [ E O D ]"
    		preprocessed_vanilla_dir=$mt_data_dir/data/training/vanilla-$threshold
    		preprocessed_equivalents_dir=$mt_data_dir/data/training/equivalence

    		mkdir -p $preprocessed_factors3_dir

    		python $scripts_dir/token2bpe_factors_convert.py \
        		--token-predictions $child_dir/data/wikimatrix/wikimatrix-$1-$2-divergence-some-difference-bicleaner-$threshold \
        		--source-subwords $preprocessed_vanilla_dir/en.tok.tc.bpe \
        		--target-subwords $preprocessed_vanilla_dir/${non_en}.tok.tc.bpe \
        		--source-subwords-eq $preprocessed_equivalents_dir/en.tok.tc.bpe \
        		--target-subwords-eq $preprocessed_equivalents_dir/${non_en}.tok.tc.bpe \
        		--output-path $preprocessed_factors3_dir/factors \
        		--source-subwords-dev $mt_data_dir/data/$subfile2/en.tok.tc.bpe.vanilla-$threshold \
        		--target-subwords-dev $mt_data_dir/data/$subfile2/${non_en}.tok.tc.bpe.vanilla-$threshold \
        		--source-subwords-test $mt_data_dir/data/$subfile/en.tok.tc.bpe.vanilla-$threshold \
        		--target-subwords-test $mt_data_dir/data/$subfile/${non_en}.tok.tc.bpe.vanilla-$threshold \
        		--tgt $non_en \
        		--num-factors 3
	#fi;


        # Step 5d: Create data for Factorized experiment (Two factors: [ O D ])
        preprocessed_factors2_dir=$mt_data_dir/data/training/factors2-$threshold
        #if [[ ! -f "$preprocessed_factors2_dir/factors.en" ]]; then

                echo "Create data for Factorized divergences: [ E O ]"
                preprocessed_vanilla_dir=$mt_data_dir/data/training/vanilla-$threshold
                preprocessed_equivalents_dir=$mt_data_dir/data/training/equivalence

                mkdir -p $preprocessed_factors2_dir

                python $scripts_dir/token2bpe_factors_convert.py \
                        --token-predictions $child_dir/data/wikimatrix/wikimatrix-$1-$2-divergence-some-difference-bicleaner-$threshold \
                        --source-subwords $preprocessed_vanilla_dir/en.tok.tc.bpe \
                        --target-subwords $preprocessed_vanilla_dir/${non_en}.tok.tc.bpe \
                        --source-subwords-eq $preprocessed_equivalents_dir/en.tok.tc.bpe \
                        --target-subwords-eq $preprocessed_equivalents_dir/${non_en}.tok.tc.bpe \
                        --output-path $preprocessed_factors2_dir/factors \
                        --source-subwords-dev $mt_data_dir/data/$subfile/en.tok.tc.bpe.vanilla-$threshold \
                        --target-subwords-dev $mt_data_dir/data/$subfile/${non_en}.tok.tc.bpe.vanilla-$threshold \
                        --source-subwords-test $mt_data_dir/data/$subfile2/en.tok.tc.bpe.vanilla-$threshold \
                        --target-subwords-test $mt_data_dir/data/$subfile2/${non_en}.tok.tc.bpe.vanilla-$threshold \
                        --tgt $non_en \
                        --num-factors 2
	#fi;
done
