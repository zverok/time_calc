# frozen_string_literal: true

require 'time'
require 'date'
require 'yaml'
require 'csv'

require 'pp'
require 'rspec/its'
require 'saharspec'
require 'simplecov'

require 'active_support/time_with_zone'
require 'active_support/core_ext/time' # otherwise TimeWithZone can't #to_s itself :facepalm:

if RUBY_VERSION >= '2.6'
  require 'tzinfo'

  # In tests, we want to use ActiveSupport, which still depends on "old" TZinfo (1.1+)
  # But in other tests we want to test with "proper" timezones, so we imitate some API
  # of TZInfo 2+ to not have conflicting gem versions
  class TZInfo::Timezone # rubocop:disable Style/ClassAndModuleChildren
    def dst?(time = Time.now)
      period_for_local(time).dst?
    end
  end
end

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

def tvz(str, zone)
  # :shrug:
  ActiveSupport::TimeZone[zone].parse(str, Time.now)
end

def vtvz(str, zone)
  TimeCalc::Value.new(tvz(str, zone))
end
