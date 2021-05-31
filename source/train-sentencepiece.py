#!/usr/bin/env python

# -*- coding: utf-8 -*-

"""
Created on 12 October 2020

author : eleftheria

"""

import sentencepiece as spm
import argparse

def main():
    parser = argparse.ArgumentParser(description="Train sentencepiece")
    parser.add_argument("--model_prefix", type=str)
    parser.add_argument("--input", type=str)
    parser.add_argument("--vocab_size", type=int)
    parser.add_argument("--model_type", type=str)
    o = parser.parse_args()

    spm.SentencePieceTrainer.Train('--input={} --model_prefix={} --vocab_size={} --hard_vocab_limit=false '
                                   '--model_type={}'.format(o.input, o.model_prefix, o.vocab_size, o.model_type))


if __name__ == '__main__':
    main()