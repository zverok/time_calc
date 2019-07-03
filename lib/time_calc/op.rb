# frozen_string_literal: true

class TimeCalc
  # Abstraction over chain of time math operations that can be applied to a time or date.
  #
  # @example
  #    op = TimeCalc.+(1, :day).floor(:hour)
  #    # => <TimeCalc::Op +(1 day).floor(hour)>
  #    op.call(Time.now)
  #    # => 2019-07-04 22:00:00 +0300
  #    array_of_time_values.map(&op)
  #    # => array of "next day, floor to hour" for each element
  class Op
    # @private
    attr_reader :chain

    # @note
    #   Prefer `TimeCalc.<operation>` (for example {TimeCalc#+}) to create operations.
    def initialize(chain = [])
      @chain = chain
    end

    # @private
    def inspect
      '<%s %s>' % [self.class, @chain.map { |name, *args| "#{name}(#{args.join(' ')})" }.join('.')]
    end

    TimeCalc::MATH_OPERATIONS.each do |name|
      define_method(name) { |*args| Op.new([*@chain, [name, *args]]) }
    end

    # @!method +(span, unit)
    #   Adds `+(span, unit)` to method chain
    #   @see TimeCalc#+
    #   @return [Op]
    # @!method -(span, unit)
    #   Adds `-(span, unit)` to method chain
    #   @see TimeCalc#-
    #   @return [Op]
    # @!method floor(unit)
    #   Adds `floor(span, unit)` to method chain
    #   @see TimeCalc#floor
    #   @return [Op]
    # @!method ceil(unit)
    #   Adds `ceil(span, unit)` to method chain
    #   @see TimeCalc#ceil
    #   @return [Op]
    # @!method round(unit)
    #   Adds `round(span, unit)` to method chain
    #   @see TimeCalc#round
    #   @return [Op]

    # Performs the whole chain of operation on parameter, returning the result.
    #
    # @param date_or_time [Date, Time, DateTime]
    # @return [Date, Time, DateTime] Type of the result is always the same as type of the parameter
    def call(date_or_time)
      @chain.reduce(Value.new(date_or_time)) { |val, (name, *args)|
        val.public_send(name, *args)
      }.unwrap
    end

    # Allows to pass operation with `&operation`.
    #
    # @return [Proc]
    def to_proc
      method(:call).to_proc
    end
  end
end
