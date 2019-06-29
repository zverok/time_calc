# frozen_string_literal: true

require 'backports/2.6.0/enumerable/to_h'
require 'backports/2.6.0/array/to_h'
require 'backports/2.6.0/hash/to_h'
require 'backports/2.6.0/kernel/then'
require 'backports/2.5.0/hash/slice'

class TimeCalc
  class Value
    EMPTY_HASH = {
      month: 1,
      day: 1,
      hour: 0,
      min: 0,
      sec: 0,
      subsec: 0
    }.freeze
    UNITS = %i[year month day hour min sec subsec].freeze
    ALL_UNITS = %i[year month week day hour min sec].freeze
    MULTIPLIERS = {
      sec: 1,
      min: 60,
      hour: 60 * 60,
      day: 24 * 60 * 60
    }.freeze

    SYNONYMS = {
      second: :sec,
      seconds: :sec,
      minute: :min,
      minutes: :min,
      hours: :hour,
      days: :day,
      weeks: :week,
      months: :month,
      years: :year
    }.freeze

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
        .slice(*UNITS)
        .merge(EMPTY_HASH) { |_k, val, empty| val || empty }
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

    UNITS.each { |u| define_method(u) { self[u] } }

    def [](unit)
      UNITS.include?(unit) or fail KeyError, "Undefined unit: #{unit}"
      @time.public_send(unit)
    end

    def values_at(*units)
      units.map(&method(:[]))
    end

    def to_h
      UNITS.to_h { |u| [u, self[u]] }
    end

    def merge(**attrs)
      Value.from_h(to_h.merge(attrs), utc_offset: to_time.utc_offset)
    end

    def truncate(unit)
      real_unit = guess_unit(unit)
      return floor_week if real_unit == :week

      UNITS
        .drop_while { |u| u != real_unit }
        .drop(1)
        .then { |keys| EMPTY_HASH.slice(*keys) }
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
      real_unit = guess_unit(unit)
      case real_unit
      when :sec, :min, :hour, :day
        Value.new(to_time + span * MULTIPLIERS.fetch(real_unit))
      when :week
        self.+(span * 7, :day)
      when :month
        plus_months(span)
      when :year
        merge(year: to_time.year + span)
      else
        fail ArgumentError, "Unsupported unit: #{unit} (#{real_unit})"
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

    def guess_unit(name)
      SYNONYMS
        .fetch(name, name)
        .tap { |u| ALL_UNITS.include?(u) or fail ArgumentError, "Unsupported unit: #{name}" }
    end
  end
end
