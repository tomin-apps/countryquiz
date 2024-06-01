Adding a new language
=====================
Adding a language can mean adding data in another language or adding
translation files for UI translations. Both don't need to be present for a
language.

Translators may add their name to _translations/TRANSLATORS_ file to get credit
for their work on the application's About page.

Please ask for further clarifications if something is not clear.

Adding data in new language
---------------------------
To add data in another language take a look at yaml files in assets directory.
Wikipedia is of great help here as it usually contains list of sovereign states
but be sure to double check on each country's page that the names are correct.

Start from _data\_en-GB.yaml_ by copying it to new name with the right language
code and translate all country names (_name_ and _alt_ fields), capital cities
and regions.

_name_ field contains short name commonly used in the language and _alt_ field
may contain longer official name if it is different from the value in _name_
field. _capital_ field contains list of capital cities of the country. Do not
add or remove them while translating.

_other_ field is a bit special, it contains altenative names or spellings for
the country in the language. This is good place to add former names of a
country.  _other_ field is currently not used by the application but that will
eventually change. _other_ values can be added and remove as needed.

_region_ field is continent or other region (Oceania) containing the country.
In the end there should be six unique regions. Please stick to the region in
the source file even if you disagree (e.g. in case of some transcontinental
country). You can always file issue report if you find a mistake.

It is very important to leave _iso_ field untouched as it contains country's
ISO code used internally by the application.

Do not remove or add any other lines or list items than _alt_ or _other_. If
you find something wrong, please file an issue report. Note that different
language Wikipedias may disagree on things like number of capital cities.

_alt_ should be only specified if it differs from name. _other_ list can be
specified as needed and its length may vary. Feel free to add or remove them
both for any country.

Finally add the language to _assets/data.yaml_. Put the name of the language
(in the language) to _name_ field, its ISO code to _code_ and link to Wikipedia
in that language to _url_. Hopefully there is Wikipedia written in the language
and covering all of the countries in the world.

Once everything is ready please create a pull request or an issue report
containing the new file and changes to _data.yaml_ to add data in the new
language.

Adding UI translations
----------------------
Add the language to countryquiz.pro TRANSLATIONS variable and build the app
once in Sailfish SDK. This should generate ts file for the language. Edit this
file with Qt Linguist to add translations. Create a pull request or an issue
report containing the new file to add the new language.
