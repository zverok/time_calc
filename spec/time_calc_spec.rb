RSpec.describe TimeCalc do
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

  TimeCalc::OPERATIONS.each do |op|
    describe "##{op}" do
      subject { calc.method(op) }

      its_call(2, :day) { is_expected.to ret calc.op(op, 2, :day) }
      its_call(:day) { is_expected.to ret calc.op(op, 1, :day) }
    end
  end
end