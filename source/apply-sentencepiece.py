#!/usr/bin/env python

# -*- coding: utf-8 -*-

"""
Created on 12 October 2020

author : eleftheria

"""

import sentencepiece as spm
import argparse

def main():
    parser = argparse.ArgumentParser(description="Apply sentencepiece")
    parser.add_argument("--model", type=str)
    parser.add_argument("--file", type=str)
    parser.add_argument("--output", type=str)
    o = parser.parse_args()

    sentence_piece_processor = spm.SentencePieceProcessor()
    sentence_piece_processor.Load(o.model)

    out = open(o.output, "w")
    with open(o.file, "r") as ins:
        for line in ins:
            out.write('{0}\n'.format(" ".join(sentence_piece_processor.EncodeAsPieces(line.strip()))))

    out.close()

if __name__ == '__main__':
    main()