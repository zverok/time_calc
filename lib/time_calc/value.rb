# frozen_string_literal: true

require 'backports/2.6.0/enumerable/to_h'
require 'backports/2.6.0/array/to_h'
require 'backports/2.6.0/hash/to_h'
require 'backports/2.6.0/kernel/then'
require 'backports/2.5.0/hash/slice'

class TimeCalc
  class Value
    def self.call(value)
      case value
      when Time
        new(value)
      when Value
        value
      else
        fail ArgumentError, "Unsupported value: #{value}"
      end
    end

    def self.from_h(hash, utc_offset: Time.now.utc_offset)
      hash
        .slice(*Units::STRUCTURAL)
        .merge(Units::DEFAULTS) { |_k, val, empty| val || empty }
        .tap { |h| h[:sec] += h.delete(:subsec) }
        .values
        .then { |components| Value.new(Time.new(*components, utc_offset)) }
    end

    def initialize(time)
      @time = time
    end

    def to_time
      @time
    end

    def inspect
      '#<%s(%p)>' % [self.class, to_time]
    end

    def <=>(other)
      return unless other.is_a?(self.class)

      to_time <=> other.to_time
    end

    include Comparable

    Units::ALL.each { |u| define_method(u) { self[u] } }

    def [](unit)
      Units::STRUCTURAL.include?(unit) or fail KeyError, "Undefined unit: #{unit}"
      @time.public_send(unit)
    end

    def values_at(*units)
      units.map(&method(:[]))
    end

    def to_h
      Units::STRUCTURAL.to_h { |u| [u, self[u]] }
    end

    def merge(**attrs)
      Value.from_h(to_h.merge(attrs), utc_offset: to_time.utc_offset)
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

      (to_time - f.to_time).abs < (to_time - c.to_time).abs ? f : c
    end

    def +(span, unit = nil)
      unit = Units.(unit)
      case unit
      when :sec, :min, :hour, :day
        Value.new(to_time + span * Units::MULTIPLIERS.fetch(unit))
      when :week
        self.+(span * 7, :day)
      when :month
        plus_months(span)
      when :year
        merge(year: to_time.year + span)
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

    private

    def floor_week
      extra_days = (to_time.wday.nonzero? || 7) - 1
      floor(:day).-(extra_days, :days)
    end

    def plus_months(span)
      target = to_time.month + span.to_i
      m = (target - 1) % 12 + 1
      dy = (target - 1) / 12
      merge(year: to_time.year + dy, month: m)
    end
  end
end
