#!/usr/bin/env ruby
require 'yaml'

available = YAML.load_file('config/locale_settings.yml')['available'].keys.reject { |k| k.include?("_") || k.include?('-') }.map {|k| k.to_sym }
plurals = eval(IO.read('./config/locales/cldr/plurals.rb'), binding, './config/locales/cldr/plurals.rb').keys

puts "Available locales without plurals:"
puts (available-plurals).join(", ")
