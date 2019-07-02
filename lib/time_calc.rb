# frozen_string_literal: true

require 'date'
require 'time'

require_relative 'time_calc/units'
require_relative 'time_calc/types'
require_relative 'time_calc/value'

class TimeCalc
  class << self
    alias call new

    def now
      new(Time.now)
    end

    def today
      new(Date.today)
    end

    def from(time)
      Value.new(time)
    end

    def from_now
      from(Time.now)
    end

    def from_today
      from(Date.today)
    end
  end

  def initialize(time)
    @value = Value.new(time)
  end

  def inspect
    '<%s(%s)>' % [self.class, @value.unwrap]
  end

  OPERATIONS = %i[merge truncate floor ceil round + -].freeze

  OPERATIONS.each do |name|
    define_method(name) { |*args|
      @value.public_send(name, *args).then { |res| res.is_a?(Value) ? res.unwrap : res }
    }
  end

  class << self
    OPERATIONS.each do |name|
      define_method(name) { |*args| Op.new([[name, *args]]) }
    end
  end

  # the rest: just delegate
end

require_relative 'time_calc/op'
require_relative 'time_calc/sequence'
require_relative 'time_calc/diff'
