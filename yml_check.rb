#!/usr/bin/ruby
require 'yaml'

globs = ["config/locale_settings.yml", "config/assets.yml", "config/locales/*/*.yml"]
files = []
globs.each { |glob|
  Dir.glob(glob) { |file|
    files.push file
  }
}

total = files.count
counter = 1
files.each { |file|
  puts "(#{counter}/#{total}) checking #{file}"
  counter += 1
  tmp = YAML::load open(file)
}
