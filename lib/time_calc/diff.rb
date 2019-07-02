# frozen_string_literal: true

class TimeCalc
  class Diff
    attr_reader :from, :to

    def initialize(from, to)
      @from = Value.wrap(from)
      @to = Value.wrap(to)
    end

    def inspect
      '#<%s(%s − %s)>' % [self.class, from.unwrap, to.unwrap]
    end

    def -@
      Diff.new(to, from)
    end

    def divmod(span, unit = nil)
      span, unit = 1, span if unit.nil?
      div(span, unit).then { |res|
        [res, to.convert(from.unwrap.class).+(res * span, unit).unwrap]
      }
    end

    def div(span, unit = nil)
      return -(-self).div(span, unit) if negative?

      span, unit = 1, span if unit.nil?
      unit = Units.(unit)
      singular_div(unit).div(span)
    end

    def modulo(span, unit = nil)
      divmod(span, unit).last
    end

    alias / div
    alias % modulo

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

    def exact
      from.unwrap.to_time - to.unwrap.to_time
    end

    def negative?
      exact.negative?
    end

    def positive?
      exact.positive?
    end

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
