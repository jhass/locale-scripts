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
    git checkout master
    git reset origin/master --hard
    rm -Rf config/locales
    git checkout config/locales
fi

if [ "$1" = "abort" ]; then
    exit 0
fi

# Load right ruby env if needed
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Ensure known state and fast forward push
if [ "$1" != "continue" ]; then
  git checkout master
  local_changes=$(git stash)
  git pull origin master
fi

# Pull from from web translate it and clean locale files
wti pull &&
$location/rename_locales.rb &&
$location/wti_postprocessing.rb &&

# Update rails translations
bundle update rails-i18n &&

# Commit changes
git add Gemfile.lock &&
git add config/locales &&
git commit -m "updated $(git status -s config/locales | wc -l) locale files [ci skip]" &&

# Pull locales not handled through web translate it
git pull catalan master &&

# Check for syntax errors and unavailable locales
$location/yml_check.rb
$location/unavailable_locales.rb

# Restore local changes if needed
if [ "$local_changes" != "No local changes to save" ]; then
    git stash pop
fi
