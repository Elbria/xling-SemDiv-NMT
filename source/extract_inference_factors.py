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

    parser.add_argument('--input', help='path to source subwords (divergent)')
    parser.add_argument('--output', help='path to target subwords (divergent)')
    parser.add_argument('--verbose', help="increase output verbosity", default=True)
    o = parser.parse_args()

    if o.verbose:
        logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

    inp = open(o.input,'r').readlines()
    out = open(o.output,'w')

    for line in inp:
        num=len(line.rstrip().split(' '))
        factors=['E']*num
        out.write(' '.join(factors) +'\n' )
    out.close()
            


if __name__ == '__main__':
    main()
