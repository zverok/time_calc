# frozen_string_literal: true

class TimeCalc
  # Represents difference between two time-or-date values.
  #
  # Typically created with just
  #
  # ```ruby
  # TimeCalc.(t1) - t2
  # ```
  #
  # Allows to easily and correctly calculate number of years/monthes/days/etc between two points in
  # time.
  #
  class Diff
    # @private
    attr_reader :from, :to

    # @note
    #   Typically you should prefer {TimeCalc#-} to create Diff.
    #
    # @param from [Time,Date,DateTime]
    # @param to [Time,Date,DateTime]
    def initialize(from, to)
      @from = Value.wrap(from)
      @to = Value.wrap(to)
    end

    # @private
    def inspect
      '#<%s(%s − %s)>' % [self.class, from.unwrap, to.unwrap]
    end

    # "Negates" the diff by swapping its operands.
    # @return [Diff]
    def -@
      Diff.new(to, from)
    end

    # Combination of {#div} and {#modulo} in one operation.
    #
    # @overload divmod(span, unit)
    #   @param span [Integer]
    #   @param unit [Symbol] Any of supported units (see {TimeCalc})
    #
    # @overload divmod(unit)
    #   Shortcut for `divmod(1, unit)`
    #   @param unit [Symbol] Any of supported units (see {TimeCalc})
    #
    # @return [(Integer, Time or Date or DateTime)]
    def divmod(span, unit = nil)
      span, unit = 1, span if unit.nil?
      div(span, unit).then { |res|
        [res, to.convert(from.unwrap.class).+(res * span, unit).unwrap]
      }
    end

    # @example
    #   t1 = Time.parse('2019-06-01 14:50')
    #   t2 = Time.parse('2019-06-15 12:10')
    #   (TimeCalc.(t2) - t1).div(:day)
    #   # => 13
    #   (TimeCalc.(t2) - t1).div(3, :hours)
    #   # => 111
    #
    # @overload div(span, unit)
    #   @param span [Integer]
    #   @param unit [Symbol] Any of supported units (see {TimeCalc})
    #
    # @overload div(unit)
    #   Shortcut for `div(1, unit)`. Also can called as just `.<units>` methods (like {#years})
    #   @param unit [Symbol] Any of supported units (see {TimeCalc})
    #
    # @return [Integer] Number of whole `<unit>`s between `Diff`'s operands.
    def div(span, unit = nil)
      return -(-self).div(span, unit) if negative?

      span, unit = 1, span if unit.nil?
      unit = Units.(unit)
      singular_div(unit).div(span)
    end

    # Same as integer modulo: the "rest" of whole division of the distance between two time points by
    # `<span> <units>`. This rest will be also time point, equal to `first diff operand - span units`
    #
    # @overload modulo(span, unit)
    #   @param span [Integer]
    #   @param unit [Symbol] Any of supported units (see {TimeCalc})
    #
    # @overload modulo(unit)
    #   Shortcut for `modulo(1, unit)`.
    #   @param unit [Symbol] Any of supported units (see {TimeCalc})
    #
    # @return [Time, Date or DateTime] Value is always the same type as first diff operand
    def modulo(span, unit = nil)
      divmod(span, unit).last
    end

    alias / div
    alias % modulo

    # "Factorizes" the distance between two points in time into units: years, months, weeks, days.
    #
    # @example
    #   t1 = Time.parse('2019-06-01 14:50')
    #   t2 = Time.parse('2019-06-15 12:10')
    #   (TimeCalc.(t2) - t1).factorize
    #   # => {:year=>0, :month=>0, :week=>1, :day=>6, :hour=>21, :min=>20, :sec=>0}
    #   (TimeCalc.(t2) - t1).factorize(weeks: false)
    #   # => {:year=>0, :month=>0, :day=>13, :hour=>21, :min=>20, :sec=>0}
    #   (TimeCalc.(t2) - t1).factorize(weeks: false, zeroes: false)
    #   # => {:day=>13, :hour=>21, :min=>20, :sec=>0}
    #   (TimeCalc.(t2) - t1).factorize(max: :hour)
    #   # => {:hour=>333, :min=>20, :sec=>0}
    #   (TimeCalc.(t2) - t1).factorize(max: :hour, min: :min)
    #   # => {:hour=>333, :min=>20}
    #
    # @param zeroes [true, false] Include big units (for ex., year), if they are zero
    # @param weeks [true, false] Include weeks
    # @param max [Symbol] Max unit to factorize into, from all supported units list
    # @param min [Symbol] Min unit to factorize into, from all supported units list
    # @return [Hash<Symbol => Integer>]
    def factorize(zeroes: true, max: :year, min: :sec, weeks: true)
      t = to
      f = from.convert(Time) # otherwise Date-sourced factorization is broken
      select_units(max: Units.(max), min: Units.(min), weeks: weeks)
        .inject({}) { |res, unit|
          span, t = Diff.new(f, t).divmod(unit)
          res.merge(unit => span)
        }.then { |res|
          next res if zeroes

          res.drop_while { |_, v| v.zero? }.to_h
        }
    end

    Units::SYNONYMS.to_a.flatten.each { |u| define_method(u) { div(u) } }

    # @private
    def exact
      from.unwrap.to_time - to.unwrap.to_time
    end

    # @return [true, false]
    def negative?
      exact.negative?
    end

    # @return [true, false]
    def positive?
      exact.positive?
    end

    # @return [-1, 0, 1]
    def <=>(other)
      return unless other.is_a?(Diff)

      exact <=> other.exact
    end

    include Comparable

    private

    def select_units(max:, min:, weeks:)
      Units::ALL
        .drop_while { |u| u != max }
        .reverse.drop_while { |u| u != min }.reverse
        .then { |list|
          next list if weeks

          list - %i[week]
        }
    end

    def singular_div(unit)
      case unit
      when :sec, :min, :hour, :day
        simple_div(from.unwrap, to.unwrap, unit)
      when :week
        div(7, :day)
      when :month
        month_div
      when :year
        year_div
      end
    end

    def simple_div(t1, t2, unit)
      if Types.compatible?(t1, t2)
        t1.-(t2).div(Units.multiplier_for(t1.class, unit, precise: true))
      else
        t1.to_time.-(t2.to_time).div(Units.multiplier_for(Time, unit))
      end
    end

    def month_div # rubocop:disable Metrics/AbcSize -- well... at least it is short
      ((from.year - to.year) * 12 + (from.month - to.month))
        .then { |res| from.day >= to.day ? res : res - 1 }
    end

    def year_div
      from.year.-(to.year).then { |res| to.merge(year: from.year) <= from ? res : res - 1 }
    end
  end
end
