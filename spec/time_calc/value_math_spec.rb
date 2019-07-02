# frozen_string_literal: true

require 'time_calc/value'

RSpec.describe TimeCalc::Value, 'math' do
  {
    plus: :+,
    minus: :-,
    floor: :floor,
    ceil: :ceil
    # round: :round
  }.each do |filename, sym|
    describe "##{sym}" do
      CSV.read("spec/fixtures/#{filename}.csv")
         .reject { |r| r.first.start_with?('#') } # hand-made CSV comments!
         .each do |source, *args, expected_str|
        context "#{source} #{sym} #{args.join(' ')}" do
          subject { value.public_send(sym, *real_args).unwrap }

          let(:value) { described_class.new(t(source)) }
          let(:expected) { t(expected_str) }
          let(:real_args) { args.count == 1 ? args.last.to_sym : [args.first.to_r, args.last.to_sym] }

          it { is_expected.to eq expected }
        end
      end
    end
  end
end
