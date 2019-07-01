# frozen_string_literal: true

class TimeCalc
  class Diff
    attr_reader :from, :to

    def initialize(from, to)
      @from = Value.(from)
      @to = Value.(to)
    end

    def inspect
      '#<%s(%p-%p)>' % [self.class, from.to_time, to.to_time]
    end

    def divmod(span, unit = nil)
      span, unit = 1, span if unit.nil?
      div(span, unit).then { |res| [res, to.+(res * span, unit).to_time] }
    end

    def div(span, unit = nil)
      span, unit = 1, span if unit.nil?
      unit = Units.(unit)
      singular_div(unit).div(span)
    end

    def modulo(span, unit)
      divmod(span, unit).last
    end

    def factorize
      t = to
      Unit::ALL[0..-2].inject({}) do |res, unit|
        span, t = Diff.new(from, t).divmod(unit)
        res.merge(unit => span)
      end
    end

    private

    def singular_div(unit)
      case unit
      when :sec, :min, :hour, :day
        from.to_time.-(to.to_time).div(Units::MULTIPLIERS.fetch(unit))
      when :week
        div(7, :day)
      when :month
        month_div
      when :year
        year_div
      else
        fail ArgumentError, "Unsupported unit: #{unit}"
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
