# Set directories of divergentmBERT

corpus=WikiMatrix                                   #   Corpus from which seed equivalents are extracted
sampling_method=contrastive_multi_hard              #   Sampling method for extracting divergent examples from seeds
size=50000                                          #   Number of seeds sampled from original corpus
src=en                                              #   Source language (language code)
tgt=$non_en                                         #   Target language (language code)
divergent_list=rdpg                                 #   List of divergences (e.g, 'rd' if divergences include
                                                    #                   phrase replacement and subtree deletion)

#############################################################################
src=$1
tgt=$2

# Root directories refer to divergentmBERT scripts & data
root_dir=                                 
data_dir=$root_dir/data
scripts_dir=$root_dir/source


child_dir=$PWD
child_data_dir=$child_dir/data
child_scripts_dir=$child_dir/source

exp_identifier=from_${corpus}.${src}-${tgt}.tsv.filtered_sample_${size}.moses.seed/${sampling_method}/${divergent_list}
data_dir=$root_dir/for_divergentmBERT/${exp_identifier}
output_dir=$root_dir/trained_bert/$exp_identifier
parallel_corpus_dir=$child_dir/wikimatrix_for_huggingface/$src-$tgt/wikimatrix-div-split-$SLURM_ARRAY_TASK_ID
model=bert-base-multilingual-cased
