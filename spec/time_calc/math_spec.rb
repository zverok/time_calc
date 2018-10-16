RSpec.describe TimeCalc, 'math' do
  def self.parse_op(str)
    span, unit = str.scan(/^([^a-z]+)([a-z]+)/).flatten
    [span.include?('/') ? span.to_r : span.to_i, unit.to_sym]
  end

  {
    plus: :+,
    minus: :-,
    # floor: :floor,
    # ceil: :ceil,
    # round: :round
  }.each do |filename, sym|

    describe "##{sym}" do
      CSV.read("spec/fixtures/#{filename}.csv")
        .reject { |r| r.first.start_with?('# ') } # hand-made CSV comments!
        .each do |source, span, unit, result|
          context "#{source} #{sym} #{span}#{unit}" do
            let(:src) { described_class.new(t(source)) }
            let(:res) { t(result) }

            subject { src.public_send(sym, span.to_r, unit.to_sym) }
            it { is_expected.to eq res }
          end
        end
    end
  end
end