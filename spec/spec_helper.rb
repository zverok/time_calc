require 'time'
require 'yaml'
require 'csv'

require 'rspec/its'
require 'saharspec'
require 'simplecov'

SimpleCov.start

require 'time_calc'

def t(str)
  Time.parse(str)
end

def vt(str)
  TimeCalc::Value.new(t(str))
end

