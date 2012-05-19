#!/usr/bin/env ruby

require 'yaml'

destination = "config/locales/cldr/plurals.rb"

locales = YAML.load_file("config/locale_settings.yml")["available"].keys
locales.collect! { |locale| locale[0..1] }
locales.uniq!

source_template = "tmp/cldr/*/plurals.rb"

result = "{\n"
result += '  :\'art-nvi\' => { :i18n => {:plural => { :keys => [:zero, :one, :two, :few, :other], :rule => lambda { |n| n == 0 ? :zero : n == 1 ? :one : n == 2 ? :two : n == 3 ? :few : :other }, :js_rule => \'function (n) { return n == 0 ? "zero" : n == 1 ? "one" : n == 2 ? "two" : n == 3 ? "few" : "other" }\' } } },'

locales.each do |locale|
  source = source_template.gsub("*", locale)
  if File.exists? source
    rule = open(source).read
    
    rule_body = rule.match(/lambda \{ \|n\| (.+?)\}/)[1]
    rule_body.gsub!(/:(\w+)/, "\"\\1\"")
    rule_body.gsub!(/\[([\d, ]+)\]\.include\?\(([n%\d ]+)\)/, "jQuery.inArray(\\2, [\\1]) != -1")
    rule_body.strip!
    js_rule = "function (n) { return #{rule_body} }"
    
    rule.gsub!(/\{(.+)\}/, "\\1")
    rule.gsub!("} } } }", "}, :js_rule => '#{js_rule}' } } }")
    rule.strip!
    
    result << "  #{rule},\n"
  end
end

result.chomp!(",\n")
result << "\n}"

open(destination, "w").write result
