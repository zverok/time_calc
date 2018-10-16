require_relative 'time_calc/units'
require_relative 'time_calc/util'

class TimeCalc
  class << self
    alias call new

    def now
      new(Time.now)
    end
  end

  OPERATIONS = %i[+ - floor ceil round].freeze

  attr_reader :source, :operations

  def initialize(source)
    @source = source
  end

  def op(name, span, unit)
    OPERATIONS.include?(name) or fail ArgumentError, "Unrecognized operation #{name.inspect}"
    Units.get(unit).public_send(name, source, span)
  end

  OPERATIONS.each do |name|
    define_method(name) { |span, unit = nil|
      span, unit = 1, span if unit.nil? # allow round(:year) and round(3, :years) call-sequences
      op(name, span, unit)
    }
  end
end
