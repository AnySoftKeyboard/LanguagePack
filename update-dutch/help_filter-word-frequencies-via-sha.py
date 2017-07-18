#!/usr/bin/env python3

shas = {}

inputfile = open('data/common.sha', 'r')
for line in inputfile:
    shas[line[:-1]] = None

inputfile = None
outputfile = open('data/frequencies-filtered.csv', 'w')
inputfile = open('data/frequencies.csv', 'r')
for line in inputfile:
    line = line[:-1]
    if line.split(';')[0] in shas.keys():
        outputfile.write('{}\n'.format(line))
