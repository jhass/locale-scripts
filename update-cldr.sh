#!/bin/bash

location=$(dirname $(readlink -e $0))

if [ ! -d "./config/locales" ]; then
    echo "./config/locales not found"
    exit 1
fi

export BUNDLE_GEMFILE="$location/Gemfile"
export BUNDLE_PATH="$location/vendor/bundle"
bundle install

cldr_core="$location/vendor/cldr-core"

if [ -d "$cldr_core" ]; then
  git -C "$cldr_core" pull
else
  git clone git://github.com/unicode-cldr/cldr-core.git "$cldr_core"
fi


bundle exec "$location/update-cldr.rb"
