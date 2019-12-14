# frozen_string_literal: true

require 'date'
require 'time'

require_relative 'time_calc/units'
require_relative 'time_calc/types'
require_relative 'time_calc/dst'
require_relative 'time_calc/value'

# Module for time arithmetic.
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
#
# # Construct operations to apply as a proc:
# times = ['2019-06-01 14:30', '2019-06-05 17:10', '2019-07-02 13:40'].map { |t| Time.parse(t) }
# # => [2019-06-01 14:30:00 +0300, 2019-06-05 17:10:00 +0300, 2019-07-02 13:40:00 +0300]
# times.map(&TimeCalc.+(1, :week).round(:day))
# # => [2019-06-09 00:00:00 +0300, 2019-06-13 00:00:00 +0300, 2019-07-10 00:00:00 +0300]
# ```
#
# See method docs below for details and supported arguments.
#
class TimeCalc
  class << self
    alias call new
    alias [] new

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
  #
  # # There is another shortcut for those who disapprove on `.()`
  # TimeCalc[Time.now].+(1, :month)
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

  # @!method iterate(span, unit)
  #   Like {#+}, but allows conditional skipping of some periods. Increases value by `unit`
  #   at least `span` times, on each iteration checking with block provided if this point
  #   matches desired period; if it is not, it is skipped without increasing iterations
  #   counter. Useful for "business date/time" algorithms.
  #
  #   @example
  #      # add 10 working days.
  #      TimeCalc.(Time.parse('2019-07-03 23:28:54')).iterate(10, :days) { |t| (1..5).cover?(t.wday) }
  #      # => 2019-07-17 23:28:54 +0300
  #
  #      # add 12 working hours
  #      TimeCalc.(Time.parse('2019-07-03 13:28:54')).iterate(12, :hours) { |t| (9...18).cover?(t.hour) }
  #      # => 2019-07-04 16:28:54 +0300
  #
  #      # negative spans are working, too:
  #      TimeCalc.(Time.parse('2019-07-03 13:28:54')).iterate(-12, :hours) { |t| (9...18).cover?(t.hour) }
  #      # => 2019-07-02 10:28:54 +0300
  #
  #      # zero span could be used to robustly enforce value into acceptable range
  #      # (increasing forward till block is true):
  #      TimeCalc.(Time.parse('2019-07-03 23:28:54')).iterate(0, :hours) { |t| (9...18).cover?(t.hour) }
  #      # => 2019-07-04 09:28:54 +0300
  #
  #   @param span [Integer] Could be positive or negative
  #   @param unit [Symbol]
  #   @return [Date, Time, DateTime] value of the same type that was initial wrapped value.
  #   @yield [Time/Date/DateTime] Object of wrapped class
  #   @yieldreturn [true, false] If this point in time is "suitable". If the falsey value is returned,
  #    iteration is skipped without increasing the counter.

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

  # @!method to(date_or_time)
  #   Produces {Sequence} from this value to `date_or_time`
  #
  #   @param date_or_time [Date, Time, DateTime]
  #   @return [Sequence]

  # @!method step(span, unit = nil)
  #   Produces endless {Sequence} from this value, with step specified.
  #
  #   @overload step(unit)
  #     Shortcut for `step(1, unit)`
  #     @param unit [Symbol]
  #   @overload step(span, unit)
  #     @example
  #       TimeCalc.(Time.parse('2019-06-01 14:50')).step(1, :day).take(3)
  #       # => [2019-06-01 14:50:00 +0300, 2019-06-02 14:50:00 +0300, 2019-06-03 14:50:00 +0300]
  #     @param span [Integer]
  #     @param unit [Symbol]
  #   @return [Sequence]

  # @!method for(span, unit)
  #   Produces {Sequence} from this value to `this + <span units>`
  #
  #   @example
  #     TimeCalc.(Time.parse('2019-06-01 14:50')).for(2, :weeks).step(1, :day).count
  #     # => 15
  #   @param span [Integer]
  #   @param unit [Symbol]
  #   @return [Sequence]

  # @private
  MATH_OPERATIONS = %i[merge truncate floor ceil round + - iterate].freeze
  # @private
  OPERATIONS = MATH_OPERATIONS.+(%i[to step for]).freeze

  OPERATIONS.each do |name|
    define_method(name) { |*args, **kwargs, &block|
      @value.public_send(name, *args, **kwargs, &block)
            .then { |res| res.is_a?(Value) ? res.unwrap : res }
    }
  end

  class << self
    MATH_OPERATIONS.each do |name|
      define_method(name) { |*args, &block| Op.new([[name, args, block].compact]) }
    end

    # @!parse
    #   # Creates operation to perform {#+}`(span, unit)`
    #   # @return [Op]
    #   def TimeCalc.+(span, unit); end
    #   # Creates operation to perform {#iterate}`(span, unit, &block)`
    #   # @return [Op]
    #   def TimeCalc.iterate(span, unit, &block); end
    #   # Creates operation to perform {#-}`(span, unit)`
    #   # @return [Op]
    #   def TimeCalc.-(span, unit); end
    #   # Creates operation to perform {#floor}`(unit)`
    #   # @return [Op]
    #   def TimeCalc.floor(unit); end
    #   # Creates operation to perform {#ceil}`(unit)`
    #   # @return [Op]
    #   def TimeCalc.ceil(unit); end
    #   # Creates operation to perform {#round}`(unit)`
    #   # @return [Op]
    #   def TimeCalc.round(unit); end
  end
end

require_relative 'time_calc/op'
require_relative 'time_calc/sequence'
require_relative 'time_calc/diff'
