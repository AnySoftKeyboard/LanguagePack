from math import log10

debug = False
debug = True

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
cutoff = 85
span = maxcnt - mincnt
number = 0

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
    if cnt < cutoff: #FIXME See bug https://github.com/AnySoftKeyboard/AnySoftKeyboardTools/issues/4
        continue
    number += 1
    outputfile.write('{:d}\t{}\n'.format(cnt, word))
if debug:
    print('DEBUG: Number of scaled and filtered words: {}'.format(number))
    print('DEBUG: Minimum scaled word count: {}'.format(minc))
    print('DEBUG: Cutoff (actual minimum) scaled word count: {}'.format(cutoff))
    print('DEBUG: Maximum scaled word count: {}'.format(maxc))

