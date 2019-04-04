#!/bin/sh

echo 'dictionary=main:uk,locale=uk,description=Українська,date=1414726277,version=1,MULTIPLE_WORDS_DEMOTION_RATE=50' > aosp.combined

aspell -d uk dump master | aspell -l uk expand | sed 's/ /\n/g' | while read WORD; do
	echo "word=$WORD,f=100,flags=,originalFreq=100" >> aosp.combined
done
