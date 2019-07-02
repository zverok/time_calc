# frozen_string_literal: true

require 'backports/2.6.0/enumerable/to_h'
require 'backports/2.6.0/array/to_h'
require 'backports/2.6.0/hash/to_h'
require 'backports/2.6.0/kernel/then'
require 'backports/2.5.0/hash/slice'

class TimeCalc
  class Value
    TIMEY = proc { |t| t.respond_to?(:to_time) }

    def self.wrap(value)
      case value
      when Time, Date, DateTime
        new(value)
      when Value
        value
      when TIMEY
        wrap(value.to_time)
      else
        fail ArgumentError, "Unsupported value: #{value}"
      end
    end

    # @private
    attr_reader :internal

    def initialize(time_or_date)
      @internal = time_or_date
    end

    def unwrap
      @internal
    end

    def inspect
      '#<%s(%s)>' % [self.class, internal]
    end

    def <=>(other)
      return unless other.is_a?(self.class)

      Types.compare(internal, other.internal)
    end

    include Comparable

    Units::ALL.each { |u| define_method(u) { internal.public_send(u) } }

    def merge(**attrs)
      Value.new(Types.public_send("merge_#{internal.class.name.downcase}", internal, **attrs))
    end

    def truncate(unit)
      unit = Units.(unit)
      return floor_week if unit == :week

      Units::STRUCTURAL
        .drop_while { |u| u != unit }
        .drop(1)
        .then { |keys| Units::DEFAULTS.slice(*keys) }
        .then(&method(:merge))
    end

    alias floor truncate

    def ceil(unit)
      floor(unit).then { |res| res == self ? res : res.+(1, unit) }
    end

    def round(unit)
      f, c = floor(unit), ceil(unit)

      (internal - f.internal).abs < (internal - c.internal).abs ? f : c
    end

    def +(span, unit = nil)
      unit = Units.(unit)
      case unit
      when :sec, :min, :hour, :day
        Value.new(internal + span * Units.multiplier_for(internal.class, unit))
      when :week
        self.+(span * 7, :day)
      when :month
        plus_months(span)
      when :year
        merge(year: year + span)
      end
    end

    def -(span_or_other, unit = nil)
      unit.nil? ? Diff.new(self, span_or_other) : self.+(-span_or_other, unit)
    end

    def to(tm)
      Sequence.new(from: self).to(tm)
    end

    def step(span, unit = nil)
      span, unit = 1, span if unit.nil?
      Sequence.new(from: self).step(span, unit)
    end

    def convert(klass)
      return dup if internal.class == klass

      Value.new(Types.convert(internal, klass))
    end

    private

    def floor_week
      extra_days = (internal.wday.nonzero? || 7) - 1
      floor(:day).-(extra_days, :days)
    end

    def plus_months(span)
      target = month + span.to_i
      m = (target - 1) % 12 + 1
      dy = (target - 1) / 12
      merge(year: year + dy, month: m)
    end
  end
end
