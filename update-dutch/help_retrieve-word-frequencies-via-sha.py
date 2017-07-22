#!/usr/bin/env python3

shas = {}

shasfile = open('data/frequencies-filtered.csv', 'r')
for line in shasfile:
    sha, count = line[:-1].split(';')
    shas[sha] = count

outputfile = open('data/words.tsv', 'w')
inputfile = open('data/all-correct.tsv', 'r')
for line1 in inputfile:
    (word, sha) = line1[:-1].split('\t')
    if sha in shas.keys():
        outputfile.write('{}\t{}\n'.format(word, shas[sha]))
