# French dictionaries

This new dictionary is based on [Dicollecte](https://www.dicollecte.org/home.php?prj=fr), licence [Mozilla Public License, version 2.0](http://www.mozilla.org/MPL/2.0/).

*Dicollecte* proposes 4 variants (see https://www.dicollecte.org/documentation.php?prj=fr#dicos):

> * dictionnaire «Moderne» : Commun + Moderne.
> * dictionnaire «Classique» : Commun + Moderne + Classique.
> * dictionnaire «Réforme 1990» : Commun + Réforme.
> * dictionnaire «Toutes variantes» : Commun + Moderne + Classique + Réforme + Annexe.

We build the dictionary with the *Classique* variant (version 6.1, 2017-07-10).

Two filters was used :
* remove entries with a zero *frequency index* (i.e. frequency &lt; 10<sup>-10</sup>) - 198.351 forms.
* remove entries with non-alphabetic letter(s) (b.e. "&", "µm", "kΩ", etc.) - 267 forms

TODO: Generate forms with apostrophes (article before nouns "l'enfant", pronoun before verbs "c'est", "m'ont", ...) 

## How to

1. Download and unzip the *lexique* (with the inflected forms) in the [download page](https://www.dicollecte.org/download.php?prj=fr)
   ```.sh
   wget http://www.dicollecte.org/download/fr/lexique-dicollecte-fr-v6.1.zip
   unzip lexique-dicollecte-fr-v6.1.zip
   ```
2. Convert the *lexique* ```.txt``` into a XML ```ẁordlist``` for AnySoftKeyboard.
   We create the perl script ```dicollecte2wordlist.pl```:
   ```.sh
   perl dicollecte2wordlist.pl lexique-dicollecte-fr-v6.1.txt >lexique-dicollecte-fr-v6.1.xml
   ```
3. Generate the ```src/main/res/values/words_dict_array.xml``` and ```src/main/res/raw/words_*.dict```
   ```.sh
   cd ..
   ./gradlew makeDictionary
   ```
