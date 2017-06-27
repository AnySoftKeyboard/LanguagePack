#!/usr/bin/env bash

# See also TODO on zapf.ntg.nl

python3 ./scale-word-list.py

SOURCE=data/words-scaled.tsv
HEADER=resources/words-header.xml
FOOTER=resources/words-footer.xml
TARGET=../dictionary/words.xml

if [ ! -e $SOURCE ]
then
    echo 'ERROR: Missing file '$SOURCE
    exit 1
fi

echo 'INFO: Number of lines in source is '`wc -l $SOURCE`
echo 'INFO: Number of lines in target before update is '`wc -l $TARGET`
sed 's/YYYY/'`date +%Y`'/g' $HEADER > $TARGET
sed 's/&/&amp;/g' $SOURCE|sed 's/"/&quot;/g'|sed 's/</&lt;/g'|sed 's/>/&gt;/g'|awk -F '\t' '{print "    <w f=\""$1"\">"$2}'|sed 's/$/<\/w>/g' >> $TARGET
cat $FOOTER >> $TARGET
echo 'INFO: Number of lines in target after update is '`wc -l $TARGET`

java -classpath ../../AnySoftKeyboardTools/makedictionary/build/classes/main com.anysoftkeyboard.tools.makedictionary.MainClass ../dictionary/words.xml ../src/main/res
