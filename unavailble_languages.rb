#!/usr/bin/env ruby
require 'yaml'
require 'pp'
available = YAML.load_file('config/locale_settings.yml')['available'].keys
files = Dir['config/locales/*/*.yml']
ignore = ['en-US', 'en-AU', 'en-GB', 'all']
available += ignore
regex = /.*\/(?:\w+\.)?(\w{2,3}(?:(?:_|-)[\w\d]+)?)\.yml$/
missing = {}
files.each do |file|
  if file =~ regex
    unless available.include? $1
      open(file) do |f|
        missing[$1] ||= 0
        missing[$1] += f.read.split("\n").size
      end
    end
  end
end
puts "Unavailable locales (locale:translated keys):"
pp missing
