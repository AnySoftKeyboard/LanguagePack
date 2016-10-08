#!/usr/bin/env bash

# See also https://nl.wikipedia.org/wiki/Bestand:Flag_of_the_Netherlands.svg

SOURCE=resources/store_hi_res_icon.png
TARGET=../StoreStuff/store_hi_res_icon.png

if [ ! -e $SOURCE ]
then
    echo 'ERROR: Missing file '$SOURCE
    exit 1
fi

cp -f $SOURCE $TARGET
