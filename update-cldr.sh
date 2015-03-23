#!/bin/bash

location=$(dirname $(readlink -e $0))

if [ ! -d "./config/locales" ]; then
    echo "./config/locales not found"
    exit 1
fi

export BUNDLE_GEMFILE="$location/Gemfile"
export BUNDLE_PATH="$location/vendor/bundle"
bundle install

# rm -Rf vendor/cldr
# rm -Rf tmp/cldr
# ruby -I$GEM_HOME/gems/ruby-cldr-0.0.2/lib $(which thor) cldr:download --source=http://www.unicode.org/Public/cldr/23.1/core.zip
# ruby -I$GEM_HOME/gems/ruby-cldr-0.0.2/lib $(which thor) cldr:export --components Plurals --target tmp/cldr

cldr_core="$location/vendor/cldr-core"

if [ -d "$cldr_core" ]; then
  git -C "$cldr_core" pull
else
  git clone git://github.com/unicode-cldr/cldr-core.git "$cldr_core"
fi


bundle exec "$location/update-cldr.rb"
