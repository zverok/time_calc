# frozen_string_literal: true

class TimeCalc
  class Sequence
    attr_reader :from

    def initialize(from:, to: nil, step: nil)
      @from = Value.wrap(from)
      @to = to&.then(&Value.method(:wrap))
      @step = step
    end

    def inspect
      '#<%s (%s - %s):step(%s)>' %
        [self.class, @from.unwrap, @to&.unwrap || '...', @step&.join(' ') || '???']
    end

    alias to_s inspect

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
      !@to || (@to <=> val) == direction
    end
  end
end
