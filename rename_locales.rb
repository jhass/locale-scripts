#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'

locale_code = /[\w\d_-]+/
directories = {
  "config/locales/devise/devise.*.yml" => /devise\.(#{locale_code})\.yml/,
  "config/locales/diaspora/*.yml" => /(#{locale_code})\.yml/,
  "config/locales/javascript/javascript.*.yml" => /javascript\.(#{locale_code})\.yml/,
}

mappings = YAML.load_file('.wti')['mappings']

def flip_direction?
  ARGV[0] && ARGV[0] == "revert"
end

mappings.each do |from, to|
  if flip_direction?
    tmp = to
    to = from
    from = tmp
  end
  
  directories.each do |filepattern, regex|
    Dir[filepattern].each do |file|
      filename = File.basename file
      
      if filename =~ regex
        if $1 == from
          dst = file.gsub(from, to)
          puts "#{file} -> #{File.basename dst}"
          FileUtils.mv file, dst
        end
      end
    end
  end
end
