#!/usr/bin/env ruby
# encoding: UTF-8
$KCODE = 'UTF8' unless RUBY_VERSION >= '1.9'

require 'rubygems'
require 'active_support/core_ext/hash/deep_merge'
require 'yaml'
require 'ya2yaml'
require 'fileutils'

YAML::ENGINE.yamler = 'psych'

header = <<HEADER
#   Copyright (c) 2010-2013, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.


HEADER


patterns = %w{
  config/locales/devise/devise.*.yml
  config/locales/diaspora/*.yml
  config/locales/javascript/javascript.*.yml
}

blacklist = %w{ca gl sq en en-US en-GB en-AU}.map { |code|
  patterns.map { |pattern| pattern.gsub("*", code) }
}.flatten

allow_empty = {
  %r{config/locales/javascript/javascript\.[\w_-]+\.yml} => {
    "javascripts" => {
      "timeago" => {
        "prefixAgo" => "",
        "suffixAgo" => "",
        "suffixFromNow" => "",
        "prefixFromNow" => ""
      }
    }
  }
}

mappings = YAML.load_file(".wti")["mappings"]

class Hash
  def compact!
    removed_keys = 0
    
    each do |key, val|
      removed_keys += val.compact! if val.is_a? Hash
      removed_keys += if val.nil? || ((val.is_a?(Hash) || val.is_a?(Array)) && val.empty?)
        delete(key)
        1
      else
        0
      end
    end
    
    removed_keys
  end
end

Dir[*patterns].each do |file|
  next if blacklist.include? file
  
  puts "\nProcessing #{file}:"
  data = YAML.load_file file
  removed_keys = data.compact!
  puts "\t...removed #{removed_keys} keys" if removed_keys > 0
  
  if data.empty?
    puts "\t...no keys left! Deleting file!"
    FileUtils.rm file
    puts "\t...deleted!"
    next
  end
  
  root = data.keys.first
  
  if mappings.has_key? root
    data[mappings[root]] = data.delete root
    root = mappings[root]
    puts "\t...updated root"
  end
  
  if empty_data = (allow_empty.find { |key, _| file =~ key } || []).last
    data[root] = empty_data.deep_merge data[root]
    puts "\t...restored allowed empty keys"
  end
  
  cleaned_yaml = data.ya2yaml(syck_compatible: true)
  puts "\t...converted back to yaml"
  cleaned_yaml.gsub! /^--- $/, ""
  cleaned_yaml = cleaned_yaml.split("\n").map { |line|
    line.rstrip.gsub /^(\s+[\w\d_]+:\s)([^"\s|]+)$/, "\\1\"\\2\""
  }.join("\n")
  puts "\t...cleaned and sanitized generated yaml"
  
  open(file, 'w') do |file|
    file.write header
    file.write cleaned_yaml
  end
  puts "\t...wrote header and yaml back into file"
end
