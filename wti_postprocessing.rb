#!/usr/bin/env ruby
# encoding: UTF-8
$KCODE = 'UTF8' unless RUBY_VERSION >= '1.9'

require 'rubygems'
require 'yaml'
require 'ya2yaml'
require 'fileutils'

YAML::ENGINE.yamler = 'psych'

header = <<HEADER
#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.


HEADER


patterns = [
  "config/locales/devise/devise.*.yml",
  "config/locales/diaspora/*.yml",
  "config/locales/javascript/javascript.*.yml"
]

blacklist = []
["ca", "gl", "en", "en-US", "en-GB", "en-AU" ].each do |code|
  patterns.each do |pattern|
    blacklist << pattern.gsub("*", code)
  end
end

mappings = YAML.load_file(".wti")["mappings"]

class Hash
  def clean!
    cleaned = Hash.new
    removed_keys = 0
    
    self.keys.each do |key|
      val = self[key]
      
      removed_keys += val.clean! if val.is_a?(Hash)
      
      if val.nil? ||
         ((val.is_a?(Hash) || val.is_a?(Array)) && val.empty?) #||
         #(val.is_a?(String)                     && val.strip.empty?)

        self.delete(key)
        removed_keys += 1
      end
    end
    
    return removed_keys
  end
end

patterns.each do |pattern|
  Dir[pattern].each do |file|
    unless blacklist.include?(file)
      puts
      puts "Processing #{file}:"
      data = YAML.load_file file
      puts "\t...loaded"
      removed_keys = data.clean!
      puts "\t...cleaned (removed #{removed_keys} keys)"
      unless data.empty?
        root = data.keys.first
        data[mappings[root]] = data.delete(root)  if mappings.keys.include?(root)
        puts "\t...updated root (if necessary)"
        
        cleaned_yaml = data.ya2yaml(:syck_compatible => true)
        puts "\t...converted back to yaml"
        cleaned_yaml.gsub!(/^--- $/, "")
        cleaned_lines = cleaned_yaml.split("\n")
        cleaned_lines.collect! do |line|
          line.rstrip!
          line.gsub!(/^(\s+[\w\d_]+:\s)([^"\s]+)$/, "\\1\"\\2\"")
          line
        end
        cleaned_yaml = cleaned_lines.join("\n")
        puts "\t...cleaned and sanitized generated yaml"
        
        cleaned_file = open(file, 'w')
        cleaned_file.write(header)
        puts "\t...wrote header"
        cleaned_file.write(cleaned_yaml)
        cleaned_file.close
        puts "\t...wrote yaml back into file"
      else
        puts "\t...no keys left! Deleting file!!!"
        FileUtils.rm file
        puts "\t...deleted!!!"
      end
    end
  end
end
