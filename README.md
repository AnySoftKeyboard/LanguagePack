# AnySoftKeyboard - Macedonian Language Pack

This is an expansion pack for AnySoftKeyboard.
Install AnySoftKeyboard first, and then select the desired layout from AnySoftKeyboard's Settings->Keyboards menu."

## Work in progress (**Usable at this point!** Without word-prediction and auto-correct):
- [x] Fork this repository.
- [x] Create a new branch, name it after the language.
- [x] In Android Studio, Refactor->Rename the folder/package com.anysoftkeyboard.languagepack.languagepack in the project tree, replacing the last `languagepack` with the name of the language. This will automatically change it at a couple of other locations.
- [x] Change `applicationId` in `build.gradle` in the same way.
- [x] Edit `src/main/res/xml/keyboards.xml` according to the comments in it. It references `src/main/res/xml/qwerty.xml`, so edit this as well. Have a look at all the other Language Pack branches, to get an idea, what is possible and how to correctly configure a keyboard.
- [x] If you want to add more keyboards, you can do this by copying `qwerty.xml` and add a <keyboard> element in `keyboards.xml`. The user can pre-select in the ASK settings, which keyboards she would like to have available for toggling through.
- [x] Edit `src/main/res/xml/dictionaries.xml`
- [x] Edit `src/main/res/values/strings.xml`, change the strings there and possibly add some more which are referenced in the other xml files. Also, create a new folder `src/main/res/values-XX`, where `XX` is the correspondent two-letter ISO 639-1 language code.
- [x] Edit `src/main/res/drawable/app_icon.png` to represent the language, e.g. by adding a flag. You can also add a new flag.png and reference it in the `iconResId=""` attribute in the keyboards.xml.
- [x] Put the source files for the dictionary into the dictionary/ directory. Take special care to take the conditions of the license into account, under which you obtained the data.
- [ ] Change the build.gradle to use and configure the tasks necessary. There are several different variants ([more Information](https://github.com/AnySoftKeyboard/AnySoftKeyboardTools/blob/master/README.md)):
    * `GenerateWordsListTask`
    * `GenerateWordsListFromAOSPTask`
    * `MergeWordsListTask`
- [x] Change the README.md to reflect the characteristics of your pack
- [ ] Make some screenshots and replace the files in the StoreStuff/ folder. One of them should be a 1024x500 banner.
- [x] If a branch of the language does not exist, [open an issue](https://github.com/AnySoftKeyboard/LanguagePack/issues/new) to request the creation of a new branch. As soon, as it is created, you can make a Pull Request from your forked branch to the one in the original repository. Provide translations of the following strings to your language:
    * title: "LANGUAGE Language Pack"
    * promo: "LANGUAGE language pack for AnySoftKeyboard"
    * description: "AnySoftKeyboard keyboards pack:
      LANGUAGE keyboard and dictionary.
