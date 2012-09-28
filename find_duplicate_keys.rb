#!/usr/bin/env ruby
require 'yaml'
require 'pp'
require "active_support/core_ext/hash/deep_merge"

used_keys = {}
open("tmp/i18n.log") do |file|
  lines = file.read
  lines.split("\n").each do |key|
    levels = key.split(".")
    first = levels.pop
    hash = {first => "I'm here!"}
    levels.reverse!
    levels.each do |key|
      hash = {key => hash}
    end
    used_keys.deep_merge!(hash)
  end
end

available_keys = {}
["config/locales/devise/devise.en.yml",
 "config/locales/javascript/javascript.en.yml",
 "config/locales/diaspora/en.yml"].each do |file|
  available_keys.deep_merge!(YAML.load_file(file)["en"])
end


def puts_unused(available, reference, namespace=nil)
  available.each do |key, val|
    if val.is_a? Hash
      if reference[key].is_a? Hash || reference[key].nil?
        if namespace
          new_namespace = "#{namespace}.#{key}"
        else
          new_namespace = key
        end
        puts_unused(val, reference[key] || {}, new_namespace)
      else
        print "#{namespace}." if namespace
        puts "#{key} is wtf"
      end
    else
      print "#{namespace}." if namespace
      puts "#{key} is useless" unless reference.has_key?(key)
    end
  end
end

#puts_unused available_keys, used_keys


def build_cleaned(available, reference)
  clean = {}
  available.each do |key, val|
    if val.is_a?(Hash) && (reference[key].is_a?(Hash) || reference[key].nil?)
      clean[key] = build_cleaned(val, reference[key] || {})
    else
      clean[key] = val if reference.has_key?(key)
    end
  end
  clean
end

def clean_pluralization(hash)
  clean = {}
  hash.each do |key, val|
    if val.is_a?(Hash)
      cleaned = clean_pluralization(val)
      clean[key] = cleaned if cleaned && !cleaned.empty?
    else
      clean[key] = val unless ["two", "few", "many"].include?(key)
    end
  end
  clean
end


def find_duplicates(hash, namespace=nil, strings=[], duplicates=[])
  hash.each do |key, val|
    if val.is_a? Hash
      if namespace
        new_namespace = "#{namespace}.#{key}"
      else
        new_namespace = key
      end
      strings, duplicates = find_duplicates(val, new_namespace, strings, duplicates)
    else
      if strings.include?(val)
        duplicates << val
      else
        strings << val
      end
    end
  end
  [strings, duplicates.uniq]
end

def find_occurences(hash, string, namespace=nil, occurences=[])
  hash.each do |key, val|
    if val.is_a? Hash
      if namespace
        new_namespace = "#{namespace}.#{key}"
      else
        new_namespace = key
      end
      occurences = find_occurences(val, string, new_namespace, occurences)
    elsif val == string
      key = "#{namespace}.#{key}" if namespace
      occurences <<  key
    end
  end
  occurences
end

cleaned = clean_pluralization(build_cleaned(available_keys, used_keys))

find_duplicates(cleaned)[1].each do |duplicate|
  puts "'#{duplicate}' is:"
  find_occurences(cleaned, duplicate).each do |occurence|
    puts "  #{occurence}"
  end
end
