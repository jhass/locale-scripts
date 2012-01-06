#!/usr/bin/env ruby
# encoding: UTF-8
$KCODE = 'UTF8' unless RUBY_VERSION >= '1.9'

master = "en"

excludes = ["ca", "ml", "gl", "en-US", "en-GB", "en-AU"]

directories = ["config/locales/diaspora",
               "config/locales/javascript",
               "config/locales/devise"]

code_pattern = /([a-z]{2,3}(?:-[A-Z]{2})?(?:_[a-z0-9]+)?)/

file_patterns = [/^#{code_pattern}\.yml$/,
                 /^javascript\.#{code_pattern}\.yml$/,
                 /^devise\.#{code_pattern}\.yml$/]

@whitelist = [:zero, :one, :two, :few, :many, :other]

header = <<HEADER
#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.


HEADER

require 'rubygems'
require 'yaml'
require 'ya2yaml'


files = []
directories.each do |directory|
  files += Dir[directory+"/**"]
end

master_slaves_map = {}

files.each do |file|
  file_patterns.each do |pattern|
    if File.basename(file) =~ pattern
      if $1 == master
        master_file = file
        master_slaves_map[master_file] = []
        files.delete(master_file)
        
        files.each do |file|
          if File.basename(file) =~ pattern
            master_slaves_map[master_file] << file unless excludes.include?($1)
          end
        end
      end
    end
  end
end

def delete_if_equal(master, slave)
  cleaned = {}
  
  slave.each do |key, val|
    if @whitelist.include?(key.to_sym)
      cleaned[key] = val
    elsif master.has_key?(key)
      if val.is_a?(Hash) && master[key].is_a?(Hash)
        cleaned_val = delete_if_equal(master[key], val)
        cleaned[key] = cleaned_val unless cleaned_val.empty?
      elsif val.is_a?(Hash) || master[key].is_a?(Hash)
        cleaned[key] = val unless val.empty?
      elsif val != master[key]
        cleaned[key] = val
      end
    end
  end
  
  cleaned
end

def count_keys(map)
  count = 0
  
  map.each do |key, val|
    if val.is_a?(Hash)
      count += count_keys(val)
    else
      count += 1
    end
  end
  
  count
end

master_slaves_map.each do |master_file, slaves|
  puts "With master #{master_file}:"
  master_translations = YAML.load_file(master_file)[master]
  
  slaves.each do |file|
    file_patterns.each do |pattern|
      if File.basename(file) =~ pattern
        print "  clean #{file}..."
        code = $1
        translations = YAML.load_file(file)[code]
        cleaned_translations = delete_if_equal(master_translations, translations)
        cleaned_yaml = {code => cleaned_translations}.ya2yaml(:syck_compatible => true)
        cleaned_yaml.gsub!(/^--- $/, "")
        cleaned_lines = cleaned_yaml.split("\n")
        cleaned_lines.collect! {|line| line.rstrip }
        cleaned_yaml = cleaned_lines.join("\n")

        cleaned_file = open(file, 'w')
        cleaned_file.write(header)
        cleaned_file.write(cleaned_yaml)
        cleaned_file.close
        
        puts "#{count_keys(translations)-count_keys(cleaned_translations)} keys removed"
      end
    end
  end
end
