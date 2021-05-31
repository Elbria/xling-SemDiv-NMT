#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Created on 9 October 2020

author : eleftheria
"""

import argparse
import logging
import random
import os
from tqdm import tqdm
from utils import divergent_mappings


def main():
    parser = argparse.ArgumentParser(
        description='Infuse the top percentage of parallel sentences with semantic divergences')
    parser.add_argument('--src', help='source language')
    parser.add_argument('--tgt', help='target language')
    parser.add_argument('--data-dir', help='path to synthetic divergences')
    parser.add_argument('--equiv-name', help='name of equivalents')
    parser.add_argument('--output-dir', help='output directory', default='for-MT')
    parser.add_argument('--size', help='corpus size (in lines)', default=751792)
    parser.add_argument('--sem-div', help='semantic divergence type', choices=['phrase_replacement',
                                                                               'subtree_deletion',
                                                                               'lexical_substitution',
									       'unpaired'])
    parser.add_argument('--percentage', help='percentage of infusion')
    parser.add_argument('--verbose', help="increase output verbosity", default=True)
    o = parser.parse_args()

    divergences_num = int((float(o.percentage) / 100) * o.size)
    print(divergences_num)
    if o.verbose:
        logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

    # Read files and open output
    eq = open(os.path.join(o.data_dir, o.equiv_name), 'r')
    dv = open(os.path.join(o.data_dir, 'from_' + o.equiv_name, divergent_mappings[o.sem_div]), 'r')
    dv_span_ = open(os.path.join(o.data_dir, 'from_' + o.equiv_name, divergent_mappings[o.sem_div] + '.span'), 'r')
    if o.sem_div == 'lexical_substitution':
        dv2 = open(os.path.join(o.data_dir, 'from_' + o.equiv_name, 'particularization'), 'r')
        dv2_span_ = open(os.path.join(o.data_dir, 'from_' + o.equiv_name, 'particularization.span'), 'r')

    subdirectory = os.path.join(o.output_dir, o.sem_div + "-" + o.percentage)
    try:
        os.makedirs(subdirectory)
        logging.info('Output directory created successfully!')
    except:
        logging.info('Output directory already exists!')

    output = open(os.path.join(subdirectory, 'full'), 'w')
    output_src = open(os.path.join(subdirectory, o.src), 'w')
    output_tgt = open(os.path.join(subdirectory, o.tgt), 'w')
    output_src_span = open(os.path.join(subdirectory, o.src + '.span'), 'w')
    output_tgt_span = open(os.path.join(subdirectory, o.tgt + '.span'), 'w')

    pbar = tqdm(total=o.size)

    written_divergences = 0
    for i in range(o.size):

        dv_sen = dv.readline()
        dv_span = dv_span_.readline().rstrip()

        eq_sen = '{0}\n'.format('\t'.join(eq.readline().rstrip().split('\t')[:2]))
        eq_src = '{0}\n'.format(eq_sen.rstrip().split('\t')[0])
        eq_tgt = '{0}\n'.format(eq_sen.rstrip().split('\t')[1])

        if dv_sen != 'None\n':
            dv_src = '{0}\n'.format(dv_sen.rstrip().split('\t')[0])
            dv_tgt = '{0}\n'.format(dv_sen.rstrip().split('\t')[1])
            dv_span = dv_span.split('\t')

            dv_src_span = '{0}\n'.format(dv_span[0])
            dv_tgt_span = '{0}\n'.format(dv_span[1])

        if o.sem_div == 'lexical_substitution':

            dv2_sen = dv2.readline()
            dv2_span = dv2_span_.readline().rstrip()

            if dv2_sen != 'None\n':
                dv2_src = '{0}\n'.format(dv2_sen.rstrip().split('\t')[0])
                dv2_tgt = '{0}\n'.format(dv2_sen.rstrip().split('\t')[1])

                dv2_span = dv2_span.split('\t')
                dv2_src_span = '{0}\n'.format(dv2_span[0])
                dv2_tgt_span = '{0}\n'.format(dv2_span[1])

        if written_divergences < divergences_num:

            if o.sem_div != 'lexical_substitution':

                if dv_sen != 'None\n':

                    output.write('DIV\t{0}'.format(dv_sen))
                    output_src.write(dv_src)
                    output_tgt.write(dv_tgt)
                    output_src_span.write(dv_src_span)
                    output_tgt_span.write(dv_tgt_span)

                    written_divergences += 1

                else:

                    output.write('EQ\t{0}'.format(eq_sen))
                    output_src.write(eq_src)
                    output_tgt.write(eq_tgt)

                    src_len = len(eq_src.split(' '))
                    tgt_len = len(eq_src.split(' '))
                    output_src_span.write('O ' * (src_len-1) + 'O\n')
                    output_tgt_span.write('O ' * (tgt_len-1) + 'O\n')

                    continue

            else:

                if dv_sen == 'None\n' and dv2_sen != 'None\n':

                    output.write('DIV\t{0}'.format(dv2_sen))
                    output_src.write(dv2_src)
                    output_tgt.write(dv2_tgt)
                    output_src_span.write(dv2_src_span)
                    output_tgt_span.write(dv2_tgt_span)

                    written_divergences += 1

                elif dv2_sen == 'None\n' and dv_sen != 'None\n':

                    output.write('DIV\t{0}'.format(dv_sen))
                    output_src.write(dv_src)
                    output_tgt.write(dv_tgt)
                    output_src_span.write(dv_src_span)
                    output_tgt_span.write(dv_tgt_span)

                    written_divergences += 1

                elif dv2_sen != 'None\n' and dv_sen != 'None\n':

                    choice = random.choice([0,1])

                    if choice == 0:

                        output.write('DIV\t{0}'.format(dv_sen))
                        output_src.write(dv_src)
                        output_tgt.write(dv_tgt)
                        output_src_span.write(dv_src_span)
                        output_tgt_span.write(dv_tgt_span)

                    else:
                        output.write('DIV\t{0}'.format(dv2_sen))
                        output_src.write(dv2_src)
                        output_tgt.write(dv2_tgt)
                        output_src_span.write(dv2_src_span)
                        output_tgt_span.write(dv2_tgt_span)

                    written_divergences += 1

                else:

                    output.write('EQ\t{0}'.format(eq_sen))
                    output_src.write(eq_src)
                    output_tgt.write(eq_tgt)

                    src_len = len(eq_src.split(' '))
                    tgt_len = len(eq_src.split(' '))
                    output_src_span.write('O ' * (src_len-1) + 'O\n')
                    output_tgt_span.write('O ' * (tgt_len-1) + 'O\n')
                    continue

        else:

            output.write('EQ\t{0}'.format(eq_sen))
            output_src.write(eq_src)
            output_tgt.write(eq_tgt)
            src_len = len(eq_src.split(' '))
            tgt_len = len(eq_src.split(' '))
            output_src_span.write('O ' * (src_len - 1) + 'O\n')
            output_tgt_span.write('O ' * (tgt_len - 1) + 'O\n')

        pbar.update(1)

    output.close()


if __name__ == '__main__':
    main()
