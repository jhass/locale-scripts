#!/bin/bash

location=$(dirname $(readlink -e $0))

if [ ! -d "./config/locales" ]; then
    echo "./config/locales not found"
    exit 1
fi

# Load right ruby env if needed
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

rm -Rf vendor/cldr
rm -Rf tmp/cldr
thor cldr:download --source=http://www.unicode.org/Public/cldr/21/core.zip
thor cldr:export --components Plurals --target tmp/cldr
$location/update-cldr.rb
