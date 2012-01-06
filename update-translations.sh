#!/bin/bash
location=$(dirname $(readlink -e $0))

if [ ! -d "./config/locales" ]; then
    echo "./config/locales not found"
    return 1
fi

if [ ! -d ".git" ]; then
    echo "Not a git repository"
    return 2
fi

if [ "$1" = "abort" ]; then
    git checkout master
    git reset origin/master --hard
    return 0
fi

# Load right ruby env if needed
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Ensure known state and fast forward push
git checkout master
local_changes=$(git stash)
git pull origin master

# Pull from from 99translations and clean locale files
$location/yml-helper/update-from-99translations.py
$location/yml-helper/clean_untranslated_keys.rb

# Update rails translations
bundle update rails-i18n

# Commit changes
git add Gemfile.lock
git add config/locales
git commit -am "updated $(git status -s config/locales | wc -l) locale files [ci skip]"

# Pull locales not handled through 99translations
git pull catalan master

# Check for syntax errors
$location/yh/yml_check.rb

# Restore local changes if needed
if [ "$local_changes" != "No local changes to save" ]; then
    git stash pop
fi
