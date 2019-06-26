# frozen_string_literal: true

require_relative 'time_calc/units'
require_relative 'time_calc/util'

class TimeCalc
  class << self
    alias call new

    def now
      new(Time.now)
    end
  end

  OPERATIONS = %i[+ - floor ceil round].freeze

  attr_reader :source, :operations

  def initialize(source)
    @source = source
  end

  def inspect
    '<%s(%p)>' % [self.class, source]
  end

  def op(name, span, unit)
    OPERATIONS.include?(name) or fail ArgumentError, "Unrecognized operation #{name.inspect}"
    Units.get(unit).public_send(name, source, span)
  end

  OPERATIONS.each do |name|
    define_method(name) { |span, unit = nil|
      # allow +(:year) and +(3, :years) call-sequences
      # ...and round(:tuesday) instead of round(1/7r, :week)
      span, unit = guess_span(span) if unit.nil?
      op(name, span, unit)
    }
  end

  private

  def guess_span(unit)
    if (wday = WEEKDAYS.index(unit))
      [Rational(wday, 7), :weeks]
    else
      [1, unit]
    end
  end
end
