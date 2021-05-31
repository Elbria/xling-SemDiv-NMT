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
    parser = argparse.ArgumentParser(description='Extract some meaning differences from Wikimatrix corpus using multi Bicleaner')
    parser.add_argument('--data-dir-token', help='path to directory with divergent sentences and predictions divergentmBERT token predictions')
    parser.add_argument('--data-dir-bicleaner', help='path to directory with divergent sentences and predictions Bicleaner scoress')
    parser.add_argument('--output-corpus-prefix', help='output corpus prefix')
    parser.add_argument('--bicleaner-threshold', help='bicleaner threshold (multiplied by 10, e.g a threshold of 1 will be converted into 0.1)')
    parser.add_argument('--verbose', help="increase output verbosity", default=True)
    o = parser.parse_args()

    threshold = float(o.bicleaner_threshold)*0.1
    if o.verbose:
        logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

    # Open output file
    output_sd = open(o.output_corpus_prefix + '-some-difference-bicleaner-' + str(o.bicleaner_threshold), 'w')
   
    # Read input
    token_preds = open(o.data_dir_token, 'r').readlines()
    bicleaner_preds = open(o.data_dir_bicleaner, 'r').readlines()

    for i, line in enumerate(bicleaner_preds):
        score = float(line.rstrip().split('\t')[2])
        if score < threshold:
            continue
        else:
            output_sd.write(token_preds[i])

    output_sd.close()

if __name__ == '__main__':
    main()
