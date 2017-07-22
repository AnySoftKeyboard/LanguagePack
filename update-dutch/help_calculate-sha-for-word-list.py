#!/usr/bin/env python3

from hashlib import sha512

outputfile1 = open('data/all-correct.tsv', 'w')
outputfile2 = open('data/all-correct.sha', 'w')
inputfile = open('data/all-correct.txt', 'r')
for line in inputfile:
    line = line[:-1]
    sha = sha512(line.encode('utf-8')).hexdigest()
    outputfile1.write('{}\t{}\n'.format(line, sha))
    outputfile2.write('{}\n'.format(sha))
