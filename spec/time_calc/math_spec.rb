require 'time_calc/value'

RSpec.describe TimeCalc::Value, 'math' do
  def self.parse_op(str)
    span, unit = str.scan(/^([^a-z]+)([a-z]+)/).flatten
    [span.include?('/') ? span.to_r : span.to_i, unit.to_sym]
  end

  {
    plus: :+,
    minus: :-,
    floor: :floor,
    ceil: :ceil,
    # round: :round
  }.each do |filename, sym|
    describe "##{sym}" do
      CSV.read("spec/fixtures/#{filename}.csv")
        .reject { |r| r.first.start_with?('#') } # hand-made CSV comments!
        .each do |source, *args, expected_str|
          context "#{source} #{sym} #{args.join(' ')}" do
            let(:value) { described_class.new(t(source)) }
            let(:expected) { t(expected_str) }
            let(:real_args) { args.count == 1 ? args.last.to_sym : [args.first.to_r, args.last.to_sym] }

            subject { value.public_send(sym, *real_args).to_time }
            it { is_expected.to eq expected }
          end
        end
    end
  end
end