#!/usr/bin/env bash

SOURCE=data/frequencies.csv
TARGET=data/frequencies.sha

if [ ! -e $SOURCE ]
then
    echo 'ERROR: Missing file '$SOURCE
    exit 1
fi

sort $SOURCE|awk -F ';' '{print $1}' > $TARGET
