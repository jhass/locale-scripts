#!/usr/bin/env ruby

require "yaml"
require "json"
require "pry"
require "cldr-plurals"

class CldrPlurals::DiasporaEmitter < CldrPlurals::Compiler::Emitter
  class << self

    RUBY_RUNTIME = <<-RUNTIME.lines.map {|func| func.split("#").first.strip }.join("; ")
    to_num = ->(str) { str.include?('.') ? str.to_f : str.to_i }
    _n = ->(str) { str.gsub(/(-)(.*)/, '\\2') } # absolute value of the source number (integer and decimals).
    _i = ->(str) { _n.(str).gsub(/([\\d]+)(\\..*)/, '\\1') } # integer digits of n.
    _f = ->(str) { _n.(str).gsub(/([\\d]+\\.?)(.*)/, '\\2') } # visible fractional digits in n, with trailing zeros.
    _t = ->(str) { _f.(str).gsub(/([0]+\\z)/, '') } # visible fractional digits in n, without trailing zeros.
    _v = ->(str) { _f.(str).length.to_s } # number of visible fraction digits in n, with trailing zeros.
    _w = ->(str) { _t.(str).length.to_s } # number of visible fraction digits in n, without trailing zeros.
    __n = ->(str) { to_num.(str.include?('.') ? _n.(str).gsub(/([0]+\\z)/, '').chomp('.') : _n.(str)) }
    __i = ->(str) { to_num.(_i.(str)) }
    __f = ->(str) { to_num.(_f.(str)) }
    __t = ->(str) { to_num.(_t.(str)) }
    __v = ->(str) { to_num.(_v.(str)) }
    __w = ->(str) { to_num.(_w.(str)) }
    RUNTIME

    JS_RUNTIME = "(function(){return this.buildArgsFor=function(t){return[this.n(t),this.i(t),this.f(t),this.t(t),this.v(t),this.w(t)]},this.n=function(t){return this.toNum(t.indexOf(\".\")>-1?this._n(t).replace(/([0]+\\.$)/,\"\"):this._n(t))},this.i=function(t){return this.toNum(this._i(t))},this.f=function(t){return this.toNum(this._f(t))},this.t=function(t){return this.toNum(this._t(t))},this.v=function(t){return this.toNum(this._v(t))},this.w=function(t){return this.toNum(this._w(t))},this.toNum=function(t){return 0==t.length?0:t.indexOf(\".\")>-1?parseFloat(t):parseInt(t)},this._n=function(t){return/(-)?(.*)/.exec(t)[2]},this._i=function(t){return/([\\d]+)(\\..*)?/.exec(this._n(t))[1]},this._f=function(t){return/([\\d]+\\.?)(.*)/.exec(this._n(t))[2]},this._t=function(t){return this._f(t).replace(/([0]+$)/,\"\")},this._v=function(t){return this._f(t).length.toString()},this._w=function(t){return this._t(t).length.toString()},this}).call({})"

    RUNTIME_VARS = %w(n i v w f t)

    def emit_rules(rules_list)
      "#{rules_list.locale.inspect} => {
          :i18n => {
            :plural => {
              :keys => #{[*rules_list.rules.map(&:name), :other].inspect},
              :rule => #{emit_self_contained_ruby(rules_list)},
              :js_rule => #{emit_self_contained_js(rules_list).inspect}
            }
          }
        }
      ".lines.map(&:strip).join
    end

    def emit_self_contained_ruby(rules_list)
      parts = [*rules_list.rules.map {|rule| "(#{CldrPlurals::RubyEmitter.emit_rule(rule)} ? :#{rule.name} : " }, ":other"]

      runtime = "#{RUBY_RUNTIME}; num = input.to_s; "
      runtime << RUNTIME_VARS.map {|var|
        "#{var} = __#{var}.(num)"
      }.join("; ")

      chooser = "#{parts.join}#{')' * (parts.size - 1)}"
      "->(input) { #{runtime}; #{chooser} }"
    end

    def emit_self_contained_js(rules_list)
      parts = [*rules_list.rules.map {|rule| "(#{CldrPlurals::JavascriptEmitter.emit_rule(rule)} ? '#{rule.name}' : " }, "'other'"]

      runtime = "var runtime = #{JS_RUNTIME}; var num = input.toString(); "
      runtime << RUNTIME_VARS.map {|var|
        "var #{var} = runtime.#{var}(num)"
      }.join("; ")

      chooser = "#{parts.join}#{')' * (parts.size - 1)}"
      "(function(input) { #{runtime}; return #{chooser}; })"
    end
  end
end


rules = JSON.parse(File.read(File.join(__dir__, "vendor/cldr-core/supplemental/plurals.json")))["supplemental"]["plurals-type-cardinal"]
rules = rules.map {|locale, rules|
  CldrPlurals::Compiler::RuleList.new(locale.to_sym).tap do |list|
    rules.each do |count, rule|
      count = count.split('-').last.to_sym
      next if count == :other
      list.add_rule count, rule
    end
  end
}

rules << CldrPlurals::Compiler::RuleList.new(:"art-nvi").tap do |list|
  list.add_rule :zero,  "n = 0 @integer 0 @decimal 0.0, 0.00, 0.000, 0.0000"
  list.add_rule :one,   "n = 1 @integer 1 @decimal 1.0, 1.00, 1.000, 1.0000"
  list.add_rule :two,   "n = 2 @integer 2 @decimal 2.0, 2.00, 2.000, 2.0000"
  list.add_rule :few,   "n = 3 @integer 3 @decimal 3.0, 3.00, 3.000, 3.0000"
  # list.add_rule :other, "@integer 3~10, 100, 1000, 10000, 100000, 1000000, … @decimal 0.1~0.9, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, …"
end


locales = YAML.load_file("config/locale_settings.yml")["available"].keys
locales.concat locales.map {|locale| locale.split("-")[0].split("_")[0] }
locales.uniq!
locales.sort!

destination = "config/locales/cldr/plurals.rb"
lines = rules.select {|rule| locales.include? rule.locale.to_s }
             .map {|rule| "  #{rule.to_code(:diaspora)}" }
File.write destination, "{\n#{lines.join(",\n")}\n}"
