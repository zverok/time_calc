# frozen_string_literal: true

RSpec.xdescribe TimeCalc do
  subject(:calc) { described_class.new(start) }

  let(:start) { t('2018-03-01 18:30:45') }

  it { is_expected.to have_attributes(source: start) }

  describe '.call' do
    subject { described_class.call(start) }

    it { is_expected.to have_attributes(source: start) }
  end

  describe '#op' do
    subject { calc.method(:op) }

    its_call(:+, 1, :day) { is_expected.to ret t('2018-03-02 18:30:45') }
    its_call(:*, 1, :day) { is_expected.to raise_error ArgumentError, /:*/ }
  end

  %i[+ - floor ceil round].each do |op|
    describe "##{op}" do
      subject { calc.method(op) }

      its_call(2, :day) { is_expected.to ret calc.op(op, 2, :day) }
      its_call(:day) { is_expected.to ret calc.op(op, 1, :day) }
    end
  end

  describe 'unit synonyms' do
    [
      %i[sec second seconds],
      %i[min minute minutes],
      %i[hour hours],
      %i[day days],
      %i[week weeks],
      %i[month months],
      %i[year years]
    ].each do |synonyms|
      context "with #{synonyms.join('/')}" do
        subject { synonyms.map { |unit| calc.+(1, unit) } }

        its(:'uniq.size') { is_expected.to eq 1 }
      end
    end
  end

  describe 'weekday conversions' do
    %i[sunday monday tuesday wednesday thursday friday saturday].each_with_index do |name, wday|
      context "for #{name}" do
        subject { calc.round(name) }

        its(:wday) { is_expected.to eq wday }
      end
    end
  end
end
