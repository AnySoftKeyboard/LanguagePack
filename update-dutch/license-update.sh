#!/usr/bin/env bash

SOURCE=resources/LICENSE
TARGET=../LICENSE

if [ ! -e $SOURCE ]
then
    echo 'ERROR: Missing file '$SOURCE
    exit 1
fi

sed 's/YYYY/'`date +%Y`'/g' $SOURCE > $TARGET
