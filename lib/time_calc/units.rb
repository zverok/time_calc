# frozen_string_literal: true

class TimeCalc
  module Units
    ALL = %i[year month week day hour min sec].freeze
    NATURAL = %i[year month day hour min sec].freeze
    STRUCTURAL = %i[year month day hour min sec subsec].freeze

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

    DEFAULTS = {
      month: 1,
      day: 1,
      hour: 0,
      min: 0,
      sec: 0,
      subsec: 0
    }.freeze

    MULTIPLIERS = {
      sec: 1,
      min: 60,
      hour: 60 * 60,
      day: 24 * 60 * 60
    }.freeze

    def self.call(unit)
      SYNONYMS.fetch(unit, unit)
              .tap { |u| ALL.include?(u) or fail ArgumentError, "Unsupported unit: #{u}" }
    end
  end
end
