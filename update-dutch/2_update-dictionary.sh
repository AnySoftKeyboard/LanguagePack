# See README.md

sort data/alle-goed-nuttig.txt > data/all-correct.txt
./help_calculate-sha-for-word-list.py
sort data/all-correct.sha > data/tmp
mv -f data/tmp data/all-correct.sha

comm -1 -2 data/all-correct.sha data/frequencies.sha > data/common.sha
./help_filter-word-frequencies-via-sha.py
./help_retrieve-word-frequencies-via-sha.py
./help_words-update.sh

java -classpath ../../AnySoftKeyboardTools/makedictionary/build/classes/main com.anysoftkeyboard.tools.makedictionary.MainClass ../dictionary/words.xml ../src/main/res
