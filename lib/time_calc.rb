# frozen_string_literal: true

require 'date'
require 'time'

require_relative 'time_calc/units'
require_relative 'time_calc/types'
require_relative 'time_calc/value'

# Module for time arithmetics.
#
# Examples of usage:
#
# ```ruby
# TimeCalc.(Time.now).+(1, :day)
# # => 2019-07-04 23:28:54 +0300
# TimeCalc.(Time.now).round(:hour)
# # => 2019-07-03 23:00:00 +0300
#
# # Operations with Time.now and Date.today also have their shortcuts:
# TimeCalc.now.-(3, :days)
# # => 2019-06-30 23:28:54 +0300
# TimeCalc.today.ceil(:month)
# # => #<Date: 2019-08-01 ((2458697j,0s,0n),+0s,2299161j)>
#
# # If you need to perform several operations TimeCalc.from wraps your value:
# TimeCalc.from(Time.parse('2019-06-14 13:40')).+(10, :days).floor(:week).unwrap
# # => 2019-06-24 00:00:00 +0300
#
# # TimeCalc#- also can be used to calculate difference between time values
# diff = TimeCalc.(Time.parse('2019-07-03 23:32')) - Time.parse('2019-06-14 13:40')
# # => #<TimeCalc::Diff(2019-07-03 23:32:00 +0300 − 2019-06-14 13:40:00 +0300)>
# diff.days # => 19
# diff.hours # => 465
# diff.factorize
# # => {:year=>0, :month=>0, :week=>2, :day=>5, :hour=>9, :min=>52, :sec=>0}
# diff.factorize(max: :day)
# # => {:day=>19, :hour=>9, :min=>52, :sec=>0}
#
# # Enumerable sequences of time values
# sequence = TimeCalc.(Time.parse('2019-06-14 13:40'))
#                    .to(Time.parse('2019-07-03 23:32'))
#                    .step(5, :hours)
# # => #<TimeCalc::Sequence (2019-06-14 13:40:00 +0300 - 2019-07-03 23:32:00 +0300):step(5 hours)>
# sequence.to_a
# # => [2019-06-14 13:40:00 +0300, 2019-06-14 18:40:00 +0300, 2019-06-14 23:40:00 +0300, ...
# sequence.first(2)
# # => [2019-06-14 13:40:00 +0300, 2019-06-14 18:40:00 +0300]
# ```
#
# See method docs below for details and supported arguments.
#
class TimeCalc
  class << self
    alias call new

    # Shortcut for `TimeCalc.(Time.now)`
    # @return [TimeCalc]
    def now
      new(Time.now)
    end

    # Shortcut for `TimeCalc.(Date.today)`
    # @return [TimeCalc]
    def today
      new(Date.today)
    end

    # Returns {Value} wrapper, useful for performing several operations at once:
    #
    # ```ruby
    # TimeCalc.from(Time.parse('2019-06-14 13:40')).+(10, :days).floor(:week).unwrap
    # # => 2019-06-24 00:00:00 +0300
    # ```
    #
    # @param date_or_time [Time, Date, DateTime]
    # @return [Value]
    def from(date_or_time)
      Value.new(date_or_time)
    end

    # Shortcut for `TimeCalc.from(Time.now)`
    # @return [Value]
    def from_now
      from(Time.now)
    end

    # Shortcut for `TimeCalc.from(Date.today)`
    # @return [Value]
    def from_today
      from(Date.today)
    end

    alias wrap from
    alias wrap_now from_now
    alias wrap_today from_today
  end

  # @private
  attr_reader :value

  # Creates a "temporary" wrapper, which would be unwrapped after first operation:
  #
  # ```ruby
  # TimeCalc.new(Time.now).round(:hour)
  # # => 2019-07-03 23:00:00 +0300
  # ```
  #
  # The constructor also aliased as `.call` which allows for nicer (for some eyes) code:
  #
  # ```ruby
  # TimeCalc.(Time.now).round(:hour)
  # # => 2019-07-03 23:00:00 +0300
  # ```
  #
  # See {.from} if you need to perform several math operations on same value.
  #
  # @param date_or_time [Time, Date, DateTime]
  def initialize(date_or_time)
    @value = Value.new(date_or_time)
  end

  # @private
  def inspect
    '#<%s(%s)>' % [self.class, @value.unwrap]
  end

  # @return [true,false]
  def ==(other)
    other.is_a?(self.class) && other.value == value
  end

  # @!method merge(**attrs)
  #   Replaces specified components of date/time, preserves the rest.
  #
  #   @example
  #      TimeCalc.(Date.parse('2018-06-01')).merge(year: 1983)
  #      # => #<Date: 1983-06-01>
  #
  #   @param attrs [Hash<Symbol => Integer>]
  #   @return [Time, Date, DateTime] value of the same type that was initial wrapped value.

  # @!method floor(unit)
  #   Floors (rounds down) date/time to nearest `unit`.
  #
  #   @example
  #     TimeCalc.(Time.parse('2018-06-23 12:30')).floor(:month)
  #     # => 2018-06-01 00:00:00 +0300
  #
  #   @param unit [Symbol]
  #   @return [Time, Date, DateTime] value of the same type that was initial wrapped value.

  # @!method ceil(unit)
  #   Ceils (rounds up) date/time to nearest `unit`.
  #
  #   @example
  #     TimeCalc.(Time.parse('2018-06-23 12:30')).ceil(:month)
  #     # => 2018-07-01 00:00:00 +0300
  #
  #   @param unit [Symbol]
  #   @return [Time, Date, DateTime] value of the same type that was initial wrapped value.

  # @!method round(unit)
  #   Rounds (up or down) date/time to nearest `unit`.
  #
  #   @example
  #     TimeCalc.(Time.parse('2018-06-23 12:30')).round(:month)
  #     # => 2018-07-01 00:00:00 +0300
  #
  #   @param unit [Symbol]
  #   @return [Time, Date, DateTime] value of the same type that was initial wrapped value.

  # @!method +(span, unit)
  #   Add `<span units>` to wrapped value
  #   @example
  #      TimeCalc.(Time.parse('2019-07-03 23:28:54')).+(1, :day)
  #      # => 2019-07-04 23:28:54 +0300
  #   @param span [Integer]
  #   @param unit [Symbol]
  #   @return [Date, Time, DateTime] value of the same type that was initial wrapped value.

  # @!method -(span_or_other, unit=nil)
  #   @overload -(span, unit)
  #     Subtracts `span units` from wrapped value.
  #     @param span [Integer]
  #     @param unit [Symbol]
  #     @return [Date, Time, DateTime] value of the same type that was initial wrapped value.
  #   @overload -(date_or_time)
  #     Produces {Diff}, allowing to calculate structured difference between two points in time.
  #     @example
  #       t1 = Time.parse('2019-06-01 14:50')
  #       t2 = Time.parse('2019-06-15 12:10')
  #       (TimeCalc.(t2) - t1).days
  #       # => 13
  #     @param date_or_time [Date, Time, DateTime]
  #     @return [Diff]
  #   @return [Time or Diff]

  # @private
  MATH_OPERATIONS = %i[merge truncate floor ceil round + -].freeze
  # @private
  OPERATIONS = MATH_OPERATIONS.+(%i[to step for]).freeze

  OPERATIONS.each do |name|
    define_method(name) { |*args|
      @value.public_send(name, *args).then { |res| res.is_a?(Value) ? res.unwrap : res }
    }
  end

  class << self
    MATH_OPERATIONS.each do |name|
      define_method(name) { |*args| Op.new([[name, *args]]) }
    end
  end
end

require_relative 'time_calc/op'
require_relative 'time_calc/sequence'
require_relative 'time_calc/diff'
