# frozen_string_literal: true

require_relative 'time_calc/value'

class TimeCalc
  class << self
    alias call new

    def now
      new(Time.now)
    end

    def from(time)
      Value.new(time)
    end

    def from_now
      from(Time.now)
    end
  end

  def initialize(time)
    @value = Value.new(time)
  end

  def inspect
    '<%s(%p)>' % [self.class, @value.to_time]
  end

  OPERATIONS = %i[merge truncate floor ceil round + -].freeze

  OPERATIONS.each do |name|
    define_method(name) { |*args| @value.public_send(name, *args).to_time }
  end

  class << self
    OPERATIONS.each do |name|
      define_method(name) { |*args| Op.new([[name, *args]]) }
    end
  end

  # the rest: just delegate

end

require_relative 'time_calc/op'
