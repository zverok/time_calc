RSpec.describe TimeCalc::Sequence do
  subject(:seq) { described_class.new(**args) }
  let(:args) { {from: vt('2019-06-01 14:30'), to: vt('2019-06-05 17:20'), step: [1, :day]} }

  its(:inspect) {
    is_expected.to eq '#<TimeCalc::Sequence (2019-06-01 14:30:00 +0300 - 2019-06-05 17:20:00 +0300):step(1 day)>'
  }

  describe '#each' do
    subject(:enum) { seq.each }

    context 'when fully defined' do
      it { is_expected.to be_a Enumerator }
      its(:to_a) {
        is_expected.to eq [
          t('2019-06-01 14:30'),
          t('2019-06-02 14:30'),
          t('2019-06-03 14:30'),
          t('2019-06-04 14:30'),
          t('2019-06-05 14:30')
        ]
      }
    end

    context 'when step not defined' do
      let(:args) { super().slice(:from, :to) }

      its_block { is_expected.to raise_error TypeError, /No step defined/ }
    end

    context 'when to is not defined' do
      subject { enum.first(6) }
      let(:args) { super().slice(:from, :step) }

      it {
        is_expected.to eq [
          t('2019-06-01 14:30'),
          t('2019-06-02 14:30'),
          t('2019-06-03 14:30'),
          t('2019-06-04 14:30'),
          t('2019-06-05 14:30'),
          t('2019-06-06 14:30')
        ]
      }
    end

    context 'when downwards' do
      let(:args) { {from: vt('2019-06-05 14:30'), to: vt('2019-06-01 17:20'), step: [-1, :day]} }

      its(:to_a) {
        is_expected.to eq [
          t('2019-06-05 14:30'),
          t('2019-06-04 14:30'),
          t('2019-06-03 14:30'),
          t('2019-06-02 14:30'),
        ]
      }
    end

    context 'when from=>to and step have different directions' do
      let(:args) { {from: vt('2019-06-05 14:30'), to: vt('2019-06-01 17:20'), step: [1, :day]} }

      its(:to_a) { is_expected.to eq [] }
    end
  end

  describe '#step' do
    its(:step) { is_expected.to eq [1, :day] }
    context 'with explicit span' do
      subject { seq.step(3, :days) }

      it { is_expected.to be_a(described_class).and have_attributes(from: seq.from, to: seq.to, step: [3, :days]) }
    end

    context 'with implicit span' do
      subject { seq.step(:day) }

      it { is_expected.to be_a(described_class).and have_attributes(from: seq.from, to: seq.to, step: [1, :day]) }
    end
  end

  describe '#to' do
    its(:to) { is_expected.to eq vt('2019-06-05 17:20') }

    context 'when updating' do
      subject { seq.to(t('2019-06-12 15:20')) }

      it { is_expected.to be_a(described_class).and have_attributes(from: seq.from, to: vt('2019-06-12 15:20'), step: [1, :day]) }
    end
  end

  describe '#for' do
    subject { seq.for(3, :months) }

    it { is_expected.to be_a(described_class).and have_attributes(from: seq.from, to: vt('2019-09-01 14:30'), step: [1, :day]) }
  end

  describe '#each_range'
end