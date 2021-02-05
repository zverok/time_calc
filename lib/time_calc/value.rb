# frozen_string_literal: true

require 'backports/2.6.0/enumerable/to_h'
require 'backports/2.6.0/array/to_h'
require 'backports/2.6.0/hash/to_h'
require 'backports/2.6.0/kernel/then'
require 'backports/2.5.0/hash/slice'
require 'backports/2.5.0/enumerable/all'
require 'backports/2.7.0/enumerator/produce'

class TimeCalc
  # Wrapper (one can say "monad") around date/time value, allowing to perform several TimeCalc
  # operations in a chain.
  #
  # @example
  #   TimeCalc.wrap(Time.parse('2019-06-01 14:50')).+(1, :year).-(1, :month).round(:week).unwrap
  #   # => 2020-05-04 00:00:00 +0300
  #
  class Value
    # @private
    TIMEY = proc { |t| t.respond_to?(:to_time) }

    # @private
    # Because AS::TimeWithZone so frigging smart that it returns "Time" from redefined class name.
    CLASS_NAME = Class.instance_method(:name)

    # @private
    def self.wrap(value)
      case value
      when Time, Date, DateTime
        # NB: ActiveSupport::TimeWithZone will also pass to this branch if
        # active_support/core_ext/time is required. But it is doubtfully it is not -- TWZ will be
        # mostly unusable :)
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

    # @note
    #   Prefer {TimeCalc.wrap} to create a Value.
    # @param time_or_date [Time, Date, DateTime]
    def initialize(time_or_date)
      @internal = time_or_date
    end

    # @return [Time, Date, DateTime] The value of the original type that was wrapped and processed
    def unwrap
      @internal
    end

    # @private
    def inspect
      '#<%s(%s)>' % [self.class, internal]
    end

    # @return [1, 0, -1]
    def <=>(other)
      return unless other.is_a?(self.class)

      Types.compare(internal, other.internal)
    end

    include Comparable

    Units::ALL.each { |u| define_method(u) { internal.public_send(u) } }

    def dst?
      return unless internal.respond_to?(:dst?)

      internal.dst?
    end

    # Produces new value with some components of underlying time/date replaced.
    #
    # @example
    #    TimeCalc.from(Date.parse('2018-06-01')).merge(year: 1983)
    #    # => #<TimeCalc::Value(1983-06-01)>
    #
    # @param attrs [Hash<Symbol => Integer>]
    # @return [Value]
    def merge(**attrs)
      class_name = CLASS_NAME.bind(internal.class).call.tr(':', '_')
      Value.new(Types.public_send("merge_#{class_name.downcase}", internal, **attrs))
    end

    # Truncates all time components lower than `unit`. In other words, "floors" (rounds down)
    # underlying date/time to nearest `unit`.
    #
    # @example
    #   TimeCalc.from(Time.parse('2018-06-23 12:30')).floor(:month)
    #   # => #<TimeCalc::Value(2018-06-01 00:00:00 +0300)>
    #
    # @param unit [Symbol]
    # @return Value
    def truncate(unit)
      unit = Units.(unit)
      return floor_week if unit == :week

      Units::STRUCTURAL
        .drop_while { |u| u != unit }
        .drop(1)
        .then { |keys| Units::DEFAULTS.slice(*keys) }
        .then { |attrs| merge(**attrs) } # can't simplify to &method(:merge) due to 2.7 keyword param problem
    end

    alias floor truncate

    # Ceils (rounds up) underlying date/time to nearest `unit`.
    #
    # @example
    #   TimeCalc.from(Time.parse('2018-06-23 12:30')).ceil(:month)
    #   # => #<TimeCalc::Value(2018-07-01 00:00:00 +0300)>
    #
    # @param unit [Symbol]
    # @return [Value]
    def ceil(unit)
      floor(unit).then { |res| res == self ? res : res.+(1, unit) }
    end

    # Rounds up or down underlying date/time to nearest `unit`.
    #
    # @example
    #   TimeCalc.from(Time.parse('2018-06-23 12:30')).round(:month)
    #   # => #<TimeCalc::Value(2018-07-01 00:00:00 +0300)>
    #
    # @param unit [Symbol]
    # @return Value
    def round(unit)
      f, c = floor(unit), ceil(unit)

      (internal - f.internal).abs < (internal - c.internal).abs ? f : c
    end

    # Add `<span units>` to wrapped value.
    #
    # @param span [Integer]
    # @param unit [Symbol]
    # @return [Value]
    def +(span, unit)
      unit = Units.(unit)
      case unit
      when :sec, :min, :hour, :day
        plus_seconds(span, unit)
      when :week
        self.+(span * 7, :day)
      when :month
        plus_months(span)
      when :year
        merge(year: year + span)
      end
    end

    # @overload -(span, unit)
    #   Subtracts `span units` from wrapped value.
    #   @param span [Integer]
    #   @param unit [Symbol]
    #   @return [Value]
    # @overload -(date_or_time)
    #   Produces {Diff}, allowing to calculate structured difference between two points in time.
    #   @param date_or_time [Date, Time, DateTime]
    #   @return [Diff]
    # Subtracts `span units` from wrapped value.
    def -(span_or_other, unit = nil)
      unit.nil? ? Diff.new(self, span_or_other) : self.+(-span_or_other, unit)
    end

    # Like {#+}, but allows conditional skipping of some periods. Increases value by `unit`
    # at least `span` times, on each iteration checking with block provided if this point
    # matches desired period; if it is not, it is skipped without increasing iterations
    # counter. Useful for "business date/time" algorithms.
    #
    # See {TimeCalc#iterate} for examples.
    #
    # @param span [Integer]
    # @param unit [Symbol]
    # @return [Value]
    # @yield [Time/Date/DateTime] Object of wrapped class
    # @yieldreturn [true, false] If this point in time is "suitable". If the falsey value is returned,
    #    iteration is skipped without increasing the counter.
    def iterate(span, unit)
      block_given? or fail ArgumentError, 'No block given'
      Integer === span or fail ArgumentError, 'Only integer spans are supported' # rubocop:disable Style/CaseEquality

      Enumerator.produce(self) { |v| v.+((span <=> 0).nonzero? || 1, unit) }
                .lazy.select { |v| yield(v.internal) }
                .drop(span.abs).first
    end

    # Produces {Sequence} from this value to `date_or_time`
    #
    # @param date_or_time [Date, Time, DateTime]
    # @return [Sequence]
    def to(date_or_time)
      Sequence.new(from: self).to(date_or_time)
    end

    # Produces endless {Sequence} from this value, with step specified.
    #
    # @overload step(unit)
    #   Shortcut for `step(1, unit)`
    #   @param unit [Symbol]
    # @overload step(span, unit)
    #   @param span [Integer]
    #   @param unit [Symbol]
    # @return [Sequence]
    def step(span, unit = nil)
      span, unit = 1, span if unit.nil?
      Sequence.new(from: self).step(span, unit)
    end

    # Produces {Sequence} from this value to `this + <span units>`
    #
    # @param span [Integer]
    # @param unit [Symbol]
    # @return [Sequence]
    def for(span, unit)
      to(self.+(span, unit))
    end

    # @private
    def convert(klass)
      return dup if internal.instance_of?(klass)

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

    def plus_seconds(span, unit)
      Value.new(internal + span * Units.multiplier_for(internal.class, unit))
           .then { |res| unit == :day ? DST.fix_value(res, self) : res }
    end
  end
end
