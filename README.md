This is Polish Language Pack for AnySoftKeyboard. It includes Polish keyboard
layout and dictionary. Dictionary words contains from AOSP dictionary extended
by a set collected by a custom web crawler/processor.

To generate custom list of words in a format usable by ASK, run `nlp/freq`
script. Note that it requires the following packages to be installed on your
system:

* python3-bs4 (BeautifulSoup)
* python3-requests
* python3-requests-cache (optional)

Mostly depending on number of crawled URLs (`nlp/sites.txt`), it can take some
time before a list of words is created. Pre-generated list is stored in
dictionary/words.xml.
