#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Created on 30 September 2020

author : eleftheria
"""

import numpy as np
from tqdm import tqdm
import argparse
import logging


def main():
    parser = argparse.ArgumentParser(description='Extract some meaning differences from Wikimatrix corpus using multi divergentmBERT')
    parser.add_argument('--data-dir', help='path to directory with divergent sentences and predictions\
                                            or batches if batch_mode is on')
    parser.add_argument('--output-corpus-prefix', help='output corpus prefix')
    parser.add_argument('--batch-mode', help='defines whether corpus has been processed in batches or not', action='store_true')
    parser.add_argument('--split-dir', help='prefix of subdirectories, only set if batch-mode is on', default=None)
    parser.add_argument('--number-batches', help='number of splits for input corpus, only set if batch-mode is on', default=1)
    parser.add_argument('--verbose', help="increase output verbosity", default=True)
    o = parser.parse_args()

    if o.verbose:
        logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

    # Open output file
    output_sd = open(o.output_corpus_prefix + 'some-difference', 'w')
    output_un = open(o.output_corpus_prefix + 'unrelated', 'w')
    output_percentage = open(o.output_corpus_prefix + 'div_percentage', 'w')

    for i in range(int(o.number_batches)):
         prefix = o.data_dir + '/' + o.split_dir + '-' + str(i) +  '/div-split-' + str(i) 
         predictions = open(prefix + '.predictions', 'r').readlines()
	 
         for pair in predictions:
         
             pair = pair.rstrip().split('\t')
             src_sent = pair[0]
             tgt_sent = pair[1]
             src_tags = pair[2].split(' ')
             tgt_tags = pair[3].split(' ')
             src_divs = [x for x in src_tags if x == 'D']
             tgt_divs = [x for x in tgt_tags if x == 'D']
          
             percentage= (len(src_divs) + len(tgt_divs)) / (1.0*(len(src_tags) + len(tgt_tags)))
             output_percentage.write(str(percentage) + '\n')   
             if (len(src_divs) + len(tgt_divs)) / (1.0*(len(src_tags) + len(tgt_tags))) < 0.15:
                 output_sd.write(pair[0] + '\t' + pair[1] + '\n')
             else:
                 output_un.write(pair[0] + '\t' + pair[1] + '\n')
 
    # Close filtered file
    output_sd.close()
    output_un.close()

if __name__ == '__main__':
    main()
