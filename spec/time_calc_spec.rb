# frozen_string_literal: true

RSpec.describe TimeCalc do
  describe 'instance' do
    subject(:calc) { described_class.new(start) }

    let(:start) { t('2018-03-01 18:30:45 +02') }

    its(:inspect) { is_expected.to eq '#<TimeCalc(2018-03-01 18:30:45 +0200)>' }

    it 'delegates operations that return time' do
      expect(calc.+(2, :days)).to eq t('2018-03-03 18:30:45')
      expect(calc.-(2, :days)).to eq t('2018-02-27 18:30:45')
      expect(calc.floor(:day)).to eq t('2018-03-01')
      expect(calc.ceil(:day)).to eq t('2018-03-02')
      expect(calc.round(:day)).to eq t('2018-03-02')
    end

    it 'delegates operations that return sequences' do
      expect(calc.to(t('2019-01-01'))).to eq TimeCalc::Sequence.new(from: start, to: t('2019-01-01'))
      expect(calc.step(3, :days)).to eq TimeCalc::Sequence.new(from: start, step: [3, :days])
      expect(calc.for(3, :days)).to eq TimeCalc::Sequence.new(from: start, to: t('2018-03-04 18:30:45'))
    end

    it 'delegates operations that return diff' do
      expect(calc - t('2019-01-01')).to be_a TimeCalc::Diff
    end
  end

  describe 'class' do
    it 'has shortcuts for self-creation and Value' do
      allow(Time).to receive(:now).and_return(t('2018-03-01 18:30:45'))
      allow(Date).to receive(:today).and_return(d('2018-03-01'))
      expect(described_class.now).to eq described_class.new(Time.now)
      expect(described_class.today).to eq described_class.new(Date.today)
      expect(described_class.from_now).to eq TimeCalc::Value.new(Time.now)
      expect(described_class.from_today).to eq TimeCalc::Value.new(Date.today)
    end

    it 'has shortcuts for op creation' do
      expect(described_class.+(5, :days).floor(:hour))
        .to be_an(TimeCalc::Op).and have_attributes(chain: [[:+, 5, :days], [:floor, :hour]])
    end
  end
end
