#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Created on 14 October 2020

author : eleftheria
"""

import argparse
import logging
import os
from tqdm import tqdm

null_ = '_ NULL _'
null__ = '__NULL__'
def main():
    parser = argparse.ArgumentParser(
        description='Preprocess TED data')
    parser.add_argument('--src', help='source language')
    parser.add_argument('--tgt', help='target language')
    parser.add_argument('--data-dir', help='path to synthetic divergences')
    parser.add_argument('--output-dir', help='output directory')
    parser.add_argument('--verbose', help="increase output verbosity", default=True)
    o = parser.parse_args()

    if o.verbose:
        logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

    # Read files and open output
    ted = open(os.path.join(o.data_dir), 'r').readlines()

    try:
        os.makedirs(o.output_dir)
        logging.info('Output directory created successfully!')
    except:
        logging.info('Output directory already exists!')

    output = open(os.path.join(o.output_dir, o.src + '-' + o.tgt), 'w')

    pbar = tqdm(total=len(ted))

    header = ted[0].rstrip().split('\t')
    index_src = header.index(o.src)
    index_tgt = header.index(o.tgt)

    pbar.update(1)

    for i in range(1, len(ted)):
        pbar.update(1)
        pairs = ted[i].rstrip().split('\t')
        src_sent = pairs[index_src]
        tgt_sent = pairs[index_tgt]

        if null_ in src_sent or null_ in tgt_sent or null__ in src_sent or null__ in tgt_sent:
            continue
        else:
            output.write('{0}\t{1}\n'.format(src_sent, tgt_sent))


    output.close()


if __name__ == '__main__':
    main()
