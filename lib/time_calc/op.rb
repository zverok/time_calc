class TimeCalc
  class Op
    def initialize(chain = [])
      @chain = chain
    end

    def inspect
      '<%s %s>' % [self.class, @chain.map { |name, *args| "#{name}(#{args.join(' ')})"}.join('.')]
    end

    TimeCalc::OPERATIONS.each do |name|
      define_method(name) { |*args| Op.new([*@chain, [name, *args]]) }
    end

    def call(time)
      @chain.reduce(Value.new(time)) { |val, (name, *args)| val.public_send(name, *args) }.to_time
    end

    def to_proc
      method(:call).to_proc
    end
  end
end