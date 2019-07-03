# frozen_string_literal: true

class TimeCalc
  # `Sequence` is a Enumerable, allowing to iterate from start point in time over defined step, till
  # end point or endlessly.
  #
  # @example
  #   seq = TimeCalc.(Time.parse('2019-06-01 14:50')).step(1, :day).for(2, :weeks)
  #   # => #<TimeCalc::Sequence (2019-06-01 14:50:00 +0300 - 2019-06-15 14:50:00 +0300):step(1 day)>
  #   seq.to_a
  #   # => [2019-06-01 14:50:00 +0300, 2019-06-02 14:50:00 +0300, ....
  #   seq.select(&:monday?)
  #   # => [2019-06-03 14:50:00 +0300, 2019-06-10 14:50:00 +0300]
  #
  #   # Endless sequences are useful too:
  #   seq = TimeCalc.(Time.parse('2019-06-01 14:50')).step(1, :day)
  #   # => #<TimeCalc::Sequence (2019-06-01 14:50:00 +0300 - ...):step(1 day)>
  #   seq.lazy.select(&:monday?).first(4)
  #   # => [2019-06-03 14:50:00 +0300, 2019-06-10 14:50:00 +0300, 2019-06-17 14:50:00 +0300, 2019-06-24 14:50:00 +0300]
  class Sequence
    # @return [Value] Wrapped sequence start.
    attr_reader :from

    # @note
    #   Prefer TimeCalc#to or TimeCalc#step for producing sequences.
    # @param from [Time, Date, DateTime]
    # @param to [Time, Date, DateTime, nil] `nil` produces endless sequence, which can be
    #   limited later with {#to} method.
    # @param step [(Integer, Symbol), nil] Pair of span and unit to advance sequence; no `step`
    #   produces incomplete sequence ({#each} will raise), which can be completed later with
    #   {#step} method.
    def initialize(from:, to: nil, step: nil)
      @from = Value.wrap(from)
      @to = to&.then(&Value.method(:wrap))
      @step = step
    end

    # @private
    def inspect
      '#<%s (%s - %s):step(%s)>' %
        [self.class, @from.unwrap, @to&.unwrap || '...', @step&.join(' ') || '???']
    end

    alias to_s inspect

    # @overload each
    #   @yield [Date/Time/DateTime] Next element in sequence
    #   @return [self]
    # @overload each
    #   @return [Enumerator]
    # @yield [Date/Time/DateTime] Next element in sequence
    # @return [Enumerator or self]
    def each
      fail TypeError, "No step defined for #{self}" unless @step

      return to_enum(__method__) unless block_given?

      return unless matching_direction?(@from)

      cur = @from
      while matching_direction?(cur)
        yield cur.unwrap
        cur = cur.+(*@step) # rubocop:disable Style/SelfAssignment
      end
      yield cur.unwrap if cur == @to

      self
    end

    include Enumerable

    # @overload step
    #   @return [(Integer, Symbol)] current step
    # @overload step(unit)
    #   Shortcut for `step(1, unit)`
    #   @param unit [Symbol] Any of supported units.
    #   @return [Sequence]
    # @overload step(span, unit)
    #   Produces new sequence with changed step.
    #   @param span [Ineger]
    #   @param unit [Symbol] Any of supported units.
    #   @return [Sequence]
    def step(span = nil, unit = nil)
      return @step if span.nil?

      span, unit = 1, span if unit.nil?
      Sequence.new(from: @from, to: @to, step: [span, unit])
    end

    # @overload to
    #   @return [Value] current sequence end, wrapped into {Value}
    # @overload to(date_or_time)
    #   Produces new sequence with end changed
    #   @param date_or_time [Date, Time, DateTime]
    #   @return [Sequence]
    def to(date_or_time = nil)
      return @to if date_or_time.nil?

      Sequence.new(from: @from, to: date_or_time, step: @step)
    end

    # Produces sequence ending at `from.+(span, unit)`.
    #
    # @example
    #   TimeCalc.(Time.parse('2019-06-01 14:50')).step(1, :day).for(2, :weeks).count
    #   # => 15
    #
    # @param span [Integer]
    # @param unit [Symbol] Any of supported units.
    # @return [Sequence]
    def for(span, unit)
      to(from.+(span, unit))
    end

    # @private
    def ==(other)
      other.is_a?(self.class) && from == other.from && to == other.to && step == other.step
    end

    private

    def direction
      (@step.first / @step.first.abs)
    end

    def matching_direction?(val)
      !@to || (@to <=> val) == direction
    end
  end
end
