# frozen_string_literal: true

RSpec.describe TimeCalc::Op do
  subject(:op) { described_class.new([[:+, [1, :day]], [:round, [:hour]]]) }

  its(:chain) { is_expected.to eq [[:+, [1, :day]], [:round, [:hour]]] }
  its(:inspect) { is_expected.to eq '<TimeCalc::Op +(1 day).round(hour)>' }

  describe '#<op>' do
    subject { op.floor(:day).-(1, :hour) }

    it {
      is_expected
        .to be_a(described_class)
        .and have_attributes(chain: [[:+, [1, :day]], [:round, [:hour]], [:floor, [:day]], [:-, [1, :hour]]])
    }
  end

  describe '#call' do
    subject { op.method(:call) }

    its_call(t('2019-06-28 14:30 +03')) { is_expected.to ret t('2019-06-29 15:00 +03') }
  end

  describe '#to_proc' do
    subject { op.to_proc }

    it { is_expected.to be_a Proc }
  end
end
