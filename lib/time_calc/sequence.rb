# frozen_string_literal: true

class TimeCalc
  class Sequence
    attr_reader :from

    def initialize(from:, to: nil, step: nil)
      @from = Value.(from)
      @to = to&.then(&Value.method(:call))
      @step = step
    end

    def inspect
      '#<%s (%s - %s):step(%s)>' %
        [self.class, @from.to_time, @to&.to_time || '...', @step&.join(' ') || '???']
    end

    alias to_s inspect

    def each
      fail TypeError, "No step defined for #{self}" unless @step

      return to_enum(__method__) unless block_given?

      return unless matching_direction?(@from)

      cur = @from
      while matching_direction?(cur)
        yield cur.to_time
        cur = cur.+(*@step) # rubocop:disable Style/SelfAssignment
      end
      yield cur.to_time if cur.to_time == @to.to_time
    end

    include Enumerable

    def step(span = nil, unit = nil)
      return @step if span.nil?

      span, unit = 1, span if unit.nil?
      Sequence.new(from: @from, to: @to, step: [span, unit])
    end

    def to(tm = nil)
      return @to if tm.nil?

      Sequence.new(from: @from, to: tm, step: @step)
    end

    def for(span, unit)
      to(from.+(span, unit))
    end

    private

    def direction
      (@step.first / @step.first.abs)
    end

    def matching_direction?(val)
      !@to || (@to.to_time <=> val.to_time) == direction
    end
  end
end
