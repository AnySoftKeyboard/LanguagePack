#!/usr/bin/env bash

# See also fouten-zonder-spaties-met-correcties.sh on zapf.ntg.nl

SOURCE=data/fouten-zonder-spaties-met-correcties.tsv
TARGET=../src/main/res/xml/autotext.xml

if [ ! -e $SOURCE ]
then
    echo 'ERROR: Missing file '$SOURCE
    exit 1
fi

cat resources/autotext-header.xml|sed -e 's/YYYY/'`date +%Y`'/g' > $TARGET
cat $SOURCE|sed -e 's/;.*//g'|sed -e 's/&/&amp;/g'|sed -e 's/"/&quot;/g'|sed -e 's/</&lt;/g'|sed -e 's/>/&gt;/g'|awk -F '\t' '{print "    <word src=\""$3"\">"$4}'|sed -e 's/$/<\/word>/g' >> $TARGET
cat resources/autotext-footer.xml >> $TARGET
