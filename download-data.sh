#!/usr/bin/env bash

#############################################################################
#                                                                           #
#                                                                           #
#									    #
#              Beyond Noise: Mitigating the Impact of Fine-grained 	    #
#              Semantic Divergences on Neural Machine Translation           #
#                                                                           #
#                              eleftheria                                   #
#                                                                           #
#                          ====  Step 1  ====                               #
#                                                                           #
#                  Download and prepare Wikimatrix data                     #
#                                                                           #
#                                                                           #
#############################################################################

# ==== Set variables
if [ $1 = 'en' ]; then
    non_en=$2
else
    non_en=$1
fi

# ==== Set directories
root_dir=$PWD
child_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
data_dir=$root_dir/data
scripts_dir=$root_dir/source
software_dir=$root_dir/software
moses_dir=$software_dir/moses-scripts/tokenizer

# Create output data directory
mkdir -p $data_dir

# ==> Step 1: Download Wikimatrix data for input language pair
wikimatrix_path=$data_dir/wikimatrix
if [ ! -f $wikimatrix_path/WikiMatrix.$1-$2.tsv ] ; then
    echo '> Downloading wikimatrix data from AWS'
    mkdir -p $wikimatrix_path
    cd $wikimatrix_path
    wget https://dl.fbaipublicfiles.com/laser/WikiMatrix/v1/WikiMatrix.$1-$2.tsv.gz
    cd $data_dir
    echo '> done'
fi;

# ==> Step 2: Unzip TSV file
wikimatrix_file=$wikimatrix_path/WikiMatrix.$1-$2.tsv
if [ ! -f "$wikimatrix_file" ]; then
    echo '> Unzip Wikimatrix TSV file'
    cd $wikimatrix_path
    gzip -d $wikimatrix_path/WikiMatrix.$1-$2.tsv.gz
    cd $data_dir
    echo '> done'
fi;

# ==> Step 3: Filter out Wikimatrix bitexts that are obviously noisy
wikimatrix_file=$wikimatrix_path/WikiMatrix.$1-$2.tsv
if [ ! -f "${wikimatrix_file}.filtered" ]; then
    echo '> Clean Wikimatrix TSV file (heuristic-based filtering)'
    cd $wikimatrix_path
    python $scripts_dir/filter_noise.py \
					--input-corpus $wikimatrix_file \
				        --output-corpus ${wikimatrix_file}.filtered \
				        --src $1 \
					--tgt $2 
    cd $data_dir
    echo '> done'
fi;

# ==> Step 4: Moses-preprocessing the filtered version of the corpus
wikimatrix_file=$wikimatrix_path/WikiMatrix.$1-$2.tsv.filtered
if [ ! -f "${wikimatrix_file}.moses.$1" ]; then
    cd $wikimatrix_path

    cut -f1 $wikimatrix_file > ${wikimatrix_file}.en
    cut -f2 $wikimatrix_file > ${wikimatrix_file}.$non_en

    echo '> Pre-process Wikimatrix using moses-scripts'
    # English language preprocessing
    # CAUTION: enabling -no-escape is extremenly crucial;
    #          performing HTML escaping on apostrophy & quotes outputs
    #          OOV tokens for the pre-trained language model and  
    #          oversplits them in redundant subwords
    cat ${wikimatrix_file}.en \
			      |	$moses_dir/replace-unicode-punctuation.perl \
                              | $moses_dir/normalize-punctuation.perl -l en \
			      |	$moses_dir/remove-non-printing-char.perl \
			      |	$moses_dir/tokenizer.perl -l en -no-escape \
				> $wikimatrix_file.moses.en

    # Non-English language preprocessing
    cat ${wikimatrix_file}.${non_en} | \
                                $moses_dir/replace-unicode-punctuation.perl | \
                                $moses_dir/normalize-punctuation.perl -l $non_en | \
                                $moses_dir/remove-non-printing-char.perl | \
			        $moses_dir/tokenizer.perl -l $non_en -no-escape \
			        > ${wikimatrix_file}.moses.$non_en
    cd $data_dir
    echo '> done'
fi;

# ==> Step 5: Create input file for divergentmBERT (Huggingface format)
huggingface_dir=$child_dir/wikimatrix_for_huggingface/en-$non_en
per_split_sents=500000
mkdir -p $huggingface_dir

if [ ! -f "$huggingface_dir/sentence-pairs" ]; then

   cd $huggingface_dir
   paste ${wikimatrix_file}.moses.en ${wikimatrix_file}.moses.$non_en > sentence-pairs

   split -l $per_split_sents -d -a 1 sentence-pairs split-  

   for i in split-* ; do
      
       echo "$i"
       lines=$(wc -l < "$i")
       split_dir=$huggingface_dir/wikimatrix-"$i"
       mkdir -p $split_dir
       mv "$i" $split_dir
       cd $split_dir
       
       # Pseudo file
       huggingface_file=$split_dir/test_synthetic.tsv
       yes "0" | head -n $lines > pseudo_lbl
       seq $lines > ids
       
       echo "#pseudo-label\t#1-pseudo-ID\t#2-pseudo-ID\t#english_sentence\t#french_sentence" \
             > $huggingface_file
       paste pseudo_lbl ids ids "$i" >> $huggingface_file
       rm ids pseudo_lbl
        
       cd $huggingface_dir
    done;
fi;


# ==> Step 5: Create input file for divergentmBERT (Huggingface formal)
#huggingface_dir=$child_dir/wikimatrix_for_huggingface/en-$non_en
#mkdir -p $huggingface_dir

# Pseudo file
#huggingface_file=$huggingface_dir/test_synthetic.tsv
#if [ ! -f "$huggingface_file" ]; then
#    cd $huggingface_dir
#    echo '> Create pseudo-test file for input to HuggingFace divergentmBERT'

#    paste ${wikimatrix_file}.moses.en ${wikimatrix_file}.moses.$non_en > sentence-pairs
#    lines=$(wc -l < sentence-pairs)
#    yes "0" | head -n $lines > pseudo_lbl
#    seq $lines > ids
    
#    echo "#pseudo-label\t#1-pseudo-ID\t#2-pseudo-ID\t#english_sentence\t#french_sentence" \
#	  > $huggingface_file
#    paste pseudo_lbl ids ids sentence-pairs >> $huggingface_file
#    rm ids pseudo_lbl

#    cd $data_dir
#    echo '> done'
#fi;
