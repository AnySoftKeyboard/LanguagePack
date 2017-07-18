#!/usr/bin/env python3

from math import log10
from locale import strxfrm, setlocale, LC_ALL, Error

debug = False
debug = True
try:
    setlocale(LC_ALL, "nl_NL.UTF-8")
except Error:
    try:
        setlocale(LC_ALL, "en_US.UTF-8")
    except Error:
        try:
            setlocale(LC_ALL, "en_GB.UTF-8")
        except Error:
            print('ERROR" Could not set locale.')
            exit(1)

mincnt = 100000.0 #TODO max float
maxcnt = .0
number = 0

inputfile = open('data/words.tsv', 'r')
for line in inputfile:
    (word, count) = line[:-1].split('\t')
    number += 1
    if count == '0':
        continue
    cnt = log10(float(count))
    if cnt > maxcnt:
        maxcnt = cnt
    if cnt < mincnt:
        mincnt = cnt
if debug:
    print('DEBUG: Number of words: {}'.format(number))
    print('DEBUG: Minimum word count: {}'.format(mincnt))
    print('DEBUG: Maximum word count: {}'.format(maxcnt))

minc = 100000 #TODO max int
maxc = 0
#cutoff = 25#85 FIXME extra loop
span = maxcnt - mincnt
words = {}

outputfile = open('data/words-scaled.tsv', 'w')
inputfile = open('data/words.tsv', 'r')
for line in inputfile:
    (word, count) = line[:-1].split('\t')
    if count == '0':
        continue
    cnt = log10(float(count))
    cnt = (cnt - mincnt) / span * 254.0 + 1.0
    cnt = int(cnt)
    if cnt > maxc:
        maxc = cnt
    if cnt < minc:
        minc = cnt
#    if cnt < cutoff: #FIXME See bug https://github.com/AnySoftKeyboard/AnySoftKeyboardTools/issues/4
#        continue
    if cnt not in words:
        words[cnt] = []
    words[cnt].append(word)
    
if debug:
    print('DEBUG: Minimum scaled word count: {}'.format(minc))
    print('DEBUG: Maximum scaled word count: {}'.format(maxc))

number = 0
for cnt, value in sorted(words.items(), reverse=True):
    if number == 262144: # 4 * 2^16, see also gradle.build
        break
    for word in sorted(value, key=strxfrm):
        if number != 262144:
            outputfile.write('{:d}\t{}\n'.format(cnt, word))
            number += 1

if debug:
    print('DEBUG: Number of scaled and filtered words: {}'.format(number))
