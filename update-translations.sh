#!/bin/bash
location=$(dirname $(readlink -e $0))

if [ ! -d "./config/locales" ]; then
    echo "./config/locales not found"
    exit 1
fi

if [ ! -d ".git" ]; then
    echo "Not a git repository"
    exit 2
fi

if [ "$1" = "abort" -o "$1" = "retry" ]; then
    git checkout develop
    git reset origin/develop --hard
    rm -Rf config/locales
    git checkout config/locales
fi

if [ "$1" = "abort" ]; then
    exit 0
fi

export DB=mysql

# Ensure known state and fast forward push
if [ "$1" != "continue" ]; then
  git checkout develop
  local_changes=$(git stash)
  git fetch origin
  git pull origin develop
fi

# Pull from from web translate it and clean locale files
wti pull &&
$location/rename_locales.rb &&
$location/wti_postprocessing.rb &&

# Commit changes
git add Gemfile.lock &&
git add config/locales &&
git commit -m "updated $(git status -s config/locales | wc -l) locale files [ci skip]" &&

# Pull locales not handled through web translate it
git pull catalan master &&

# Check for syntax errors and unavailable stuff
$location/yml_check.rb
$location/unavailable_locales.rb
$location/cldr_check.rb

# Restore local changes if needed
if [ "$local_changes" != "No local changes to save" ]; then
    git stash pop
fi
