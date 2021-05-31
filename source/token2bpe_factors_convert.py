#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Created on 11 December 2020

author : eleftheria
"""

import argparse
import logging
import sys

def main():
    parser = argparse.ArgumentParser(
        description='Extract subword factors from token factors')

    parser.add_argument('--token-predictions', help='path to directory with token predictions')
    parser.add_argument('--source-subwords', help='path to source subwords (vanilla)')
    parser.add_argument('--target-subwords', help='path to target subwords (vanilla)')
    parser.add_argument('--source-subwords-eq', help='path to source subwords (equivalent)')
    parser.add_argument('--target-subwords-eq', help='path to target subwords (equivalent)')
    parser.add_argument('--source-subwords-dev', help='development set source subwords')
    parser.add_argument('--target-subwords-dev', help='development set target subwords')
    parser.add_argument('--source-subwords-test', help='test set source subwords')
    parser.add_argument('--target-subwords-test', help='test set target subwords')
    parser.add_argument('--output-path', help='output path for saving subword factors')
    parser.add_argument('--src', help='source language', default='en')
    parser.add_argument('--tgt', help='target language', default='fr')
    parser.add_argument('--num-factors', help='number of factors', default=3)
    parser.add_argument('--verbose', help="increase output verbosity", default=True)
    o = parser.parse_args()

    if o.verbose:
        logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

    ## Create source factors for test set

    src_test = open(o.source_subwords_test, 'r')
    tgt_test = open(o.target_subwords_test, 'r')
    src_test_factors = open(o.source_subwords_test + '.factors.' + o.num_factors, 'w')
    tgt_test_factors = open(o.target_subwords_test + '.factors.' + o.num_factors, 'w')

    # Read file (not in memory)
    line = src_test.readline()
    while line:
        src_length = len(line.rstrip().split(' '))
        if int(o.num_factors) == 2:
            eq_tags = ['O']*src_length
        else:
            eq_tags = ['E']*src_length
        src_test_factors.write(' '.join(eq_tags) + '\n')
        line = src_test.readline()

    # Read file (not in memory)
    line = tgt_test.readline()
    while line:
        tgt_length = len(line.rstrip().split(' '))
        if int(o.num_factors) == 2:
            eq_tags = ['O']*tgt_length
        else:
            eq_tags = ['E']*tgt_length
        tgt_test_factors.write(' '.join(eq_tags) + '\n')
        line = tgt_test.readline()

    ## Create source/target factors for development sets

    src_dev = open(o.source_subwords_dev, 'r')
    tgt_dev = open(o.target_subwords_dev, 'r')
    src_dev_factors = open(o.source_subwords_dev + '.factors.' + o.num_factors, 'w')
    tgt_dev_factors = open(o.target_subwords_dev + '.factors.' + o.num_factors, 'w')

    # Read file (not in memory)
    line = src_dev.readline()
    while line:
        src_length = len(line.rstrip().split(' '))
        if int(o.num_factors)==2:
            eq_tags = ['O']*src_length
        else:
            eq_tags = ['E']*src_length
        src_dev_factors.write(' '.join(eq_tags) + '\n')
        line = src_dev.readline()

    line = tgt_dev.readline()
    while line:
        tgt_length = len(line.rstrip().split(' '))
        if int(o.num_factors)==2:
            eq_tags = ['O']*tgt_length
        else:
            eq_tags = ['E']*tgt_length
        tgt_dev_factors.write(' '.join(eq_tags) + '\n')
        line = tgt_dev.readline()

    
    # Open output file
    output_src = open(o.output_path + '.' + o.src, 'w')
    output_tgt = open(o.output_path + '.' + o.tgt, 'w')

    ############################################################

    ## Create equivalents

    num_eq = len(open(o.source_subwords_eq, 'r').readlines())
    src_ = open(o.source_subwords, 'r')
    tgt_ = open(o.target_subwords, 'r')

    count_eq = 1
    # Read file (not in memory)
    line = src_.readline()
    while count_eq < num_eq:
        count_eq+= 1
        src_length = len(line.rstrip().split(' '))
        if int(o.num_factors)==2:
            eq_tags = ['O']*src_length
        else:
            eq_tags = ['E']*src_length
        output_src.write(' '.join(eq_tags) + '\n')
        line = src_.readline()

    src_length = len(line.rstrip().split(' '))
    if int(o.num_factors)==2:
        eq_tags = ['O']*src_length
    else:
        eq_tags = ['E']*src_length
    output_src.write(' '.join(eq_tags) + '\n')

    count_eq = 1
    line = tgt_.readline()
    while count_eq < num_eq:
        count_eq += 1
        tgt_length = len(line.rstrip().split(' '))
        if int(o.num_factors)==2:
            eq_tags = ['O']*tgt_length
        else:
            eq_tags = ['E']*tgt_length
        output_tgt.write(' '.join(eq_tags) + '\n')
        line = tgt_.readline()

    tgt_length = len(line.rstrip().split(' '))
    if int(o.num_factors)==2:
        eq_tags = ['O']*tgt_length
    else:
        eq_tags = ['E']*tgt_length
    output_tgt.write(' '.join(eq_tags) + '\n')
    ############################################################
    
    ## Create divergent tags

    token_preds = open(o.token_predictions, 'r')
   
    # Source
    line = src_.readline()
    #print(line)
    preds_ = token_preds.readline()
    #line = src_div.readline()
    #print(line)
    #print(preds_) 
    while line:
        preds = preds_.rstrip().split('\t')[2].split(' ')
        bpes = line.rstrip().split(' ')
        #print(line)
        #print(preds) 
        index_helper = -1
        bpes_predictions = []
        for bpe in bpes:
            if bpe[0] == '▁':

                index_helper += 1
                bpes_predictions.append(preds[index_helper])
            else:
                bpes_predictions.append(preds[index_helper])
        if str(len(bpes_predictions))!=str(len(bpes)):
            print(str(len(bpes_predictions)) + '\t' + str(len(bpes)))
        output_src.write(' '.join(bpes_predictions) + '\n')
        line_pr = line
        line = src_.readline()
        preds_ = token_preds.readline()
    #print(line_pr)

    # Target
    token_preds.close()
    token_preds = open(o.token_predictions, 'r')
    line = tgt_.readline()
    preds__ = token_preds.readline()

    #line = tgt_div.readline()

    while line:
     
        preds = preds__.rstrip().split('\t')[3].split(' ')
        bpes = line.rstrip().split(' ')

        index_helper = -1
        bpes_predictions = []
        for bpe in bpes:
            if bpe[0] == '▁':
                index_helper += 1
                bpes_predictions.append(preds[index_helper])
            else:
                bpes_predictions.append(preds[index_helper])

        output_tgt.write(' '.join(bpes_predictions) + '\n')
        line = tgt_.readline()
        preds__ = token_preds.readline()

    ############################################################

    # Close tagged file
    output_src.close()
    output_tgt.close()


if __name__ == '__main__':
    main()
