# -*- coding: utf-8 -*-

"""
Created on 9 October 2020

@author: eleftheria
"""

from nltk import ngrams
import numpy as np


divergent_mappings = {
                        'phrase_replacement': 'replace',
                        'subtree_deletion': 'delete',
                        'lexical_substitution': 'generalization',
		        'unpaired': 'uneven'
                      }
