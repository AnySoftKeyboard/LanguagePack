This is Polish Language Pack for AnySoftKeyboard. It includes Polish keyboard
layout and dictionary. Dictionary words contains from AOSP dictionary extended
by a set collected by a custom web crawler/processor.

To generate custom list of words in a format usable by ASK, run `nlp/freq`
script. It will analyze `dictionary/input` directory and save results to
`dictionary/words.xml`.

Input directory can be propagated e.g. by running `nlp/get_sites` script (which
accepts URLs on its standard input). Gzipped and raw text files are accepted. To
obtain all links from any website, you can use `nlp/links` script.

NLP scripts require the following packages:

* python3-bs4 (BeautifulSoup)
* python3-requests
