#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Created on 28 September 2020

author : eleftheria
"""

import numpy as np
from tqdm import tqdm
import argparse
import logging


def main():
    parser = argparse.ArgumentParser(description='Extract no meaning differences from Wikimatrix corpus using divergentmBERT')
    parser.add_argument('--data-dir', help='path to directory with parallel sentences and predictions\
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
    output_eq = open(o.output_corpus_prefix + 'equivalence', 'w')
    output_dv = open(o.output_corpus_prefix + 'divergence', 'w')

    for i in range(int(o.number_batches)):
         prefix = o.data_dir + '/' + o.split_dir + '-' + str(i) +  '/split-' + str(i) 
         sentences = open(prefix, 'r').readlines()
         predictions = open(prefix + '.predictions', 'r').readlines()
	 
         for j, pair in enumerate(sentences):
             pred = int(predictions[j].rstrip().split('\t')[0])
             if pred == 0:
                 output_eq.write(pair)
             else:
                 output_dv.write(pair)
 
    # Close filtered file
    output_eq.close()
    output_dv.close()

if __name__ == '__main__':
    main()
