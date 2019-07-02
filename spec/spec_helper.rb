# frozen_string_literal: true

require 'time'
require 'date'
require 'yaml'
require 'csv'

require 'pp'
require 'rspec/its'
require 'saharspec'
require 'simplecov'

SimpleCov.start

require 'time_calc'

def t(str)
  Time.parse(str)
end

def d(str)
  Date.parse(str)
end

def dt(str)
  DateTime.parse(str)
end

def vt(str)
  TimeCalc::Value.new(t(str))
end

def vd(str)
  TimeCalc::Value.new(d(str))
end

def vdt(str)
  TimeCalc::Value.new(dt(str))
end
