#!/usr/bin/env bash

# See also fouten-zonder-spaties-met-correcties.sh on zapf.ntg.nl

SOURCE=resources/LICENSE
TARGET=../LICENSE

if [ ! -e $SOURCE ]
then
    echo 'ERROR: Missing file '$SOURCE
    exit 1
fi

sed 's/YYYY/'`date +%Y`'/g' $SOURCE > $TARGET
