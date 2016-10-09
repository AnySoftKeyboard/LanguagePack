#!/usr/bin/env bash

# See also
# https://nl.wikipedia.org/wiki/Bestand:Flag_of_the_Netherlands.svg
# https://commons.wikimedia.org/wiki/File:Flag_of_Belgium.svg
# https://commons.wikimedia.org/wiki/File:Flag_of_Suriname.svg

SOURCE=resources/store_hi_res_icon.png
TARGET=../StoreStuff/store_hi_res_icon.png

if [ ! -e $SOURCE ]
then
    echo 'ERROR: Missing file '$SOURCE
    exit 1
fi

cp -f $SOURCE $TARGET
convert $SOURCE -resize 48x48 ../src/main/res/drawable/app_icon.png
convert $SOURCE -resize 72x72 ../src/main/res/drawable-hdpi/app_icon.png
convert $SOURCE -resize 96x96 ../src/main/res/drawable-xhdpi/app_icon.png
