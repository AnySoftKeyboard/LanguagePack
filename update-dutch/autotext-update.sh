#!/usr/bin/env bash

# See also fouten-zonder-spaties-met-correcties.sh on zapf.ntg.nl

SOURCE=data/fouten-zonder-spaties-met-correcties.tsv
HEADER=resources/autotext-header.xml
FOOTER=resources/autotext-footer.xml
TARGET=../src/main/res/xml/autotext.xml

if [ ! -e $SOURCE ]
then
    echo 'ERROR: Missing file '$SOURCE
    exit 1
fi

echo 'INFO: Number of lines in source is '`wc -l $SOURCE`
echo 'INFO: Number of lines in target before update is '`wc -l $TARGET`
sed 's/YYYY/'`date +%Y`'/g' $HEADER > $TARGET
sed 's/;.*//g' $SOURCE|sed 's/&/&amp;/g'|sed 's/"/&quot;/g'|sed 's/</&lt;/g'|sed 's/>/&gt;/g'|awk -F '\t' '{print "    <word src=\""$3"\">"$4}'|sed 's/$/<\/word>/g' >> $TARGET
cat $FOOTER >> $TARGET
echo 'INFO: Number of lines in target after update is '`wc -l $TARGET`
