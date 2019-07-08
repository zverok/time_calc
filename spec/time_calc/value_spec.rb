# frozen_string_literal: true

require 'time_calc/value'

RSpec.describe TimeCalc::Value do
  subject(:value) { described_class.new(source) }

  describe '.wrap' do
    subject { described_class.method(:wrap) }

    its_call(t('2019-06-28 14:28:48.123 +03')) {
      is_expected.to ret be_a(described_class).and have_attributes(unwrap: t('2019-06-28 14:28:48.123 +03'))
    }
    its_call(d('2019-06-28')) {
      is_expected.to ret be_a(described_class).and have_attributes(unwrap: d('2019-06-28'))
    }
    its_call(dt('2019-06-28 14:28:48.123 +03')) {
      is_expected.to ret be_a(described_class).and have_attributes(unwrap: dt('2019-06-28 14:28:48.123 +03'))
    }
    its_call('2019-06-28 14:28:48.123 +03') {
      is_expected.to raise_error ArgumentError
    }

    o1 = Object.new.tap { |obj|
      def obj.to_time
        t('2019-06-28 14:28:48.123 +03')
      end
    }
    its_call(o1) {
      is_expected.to ret be_a(described_class).and have_attributes(unwrap: t('2019-06-28 14:28:48.123 +03'))
    }
    o2 = Object.new.tap { |obj| # not something time-alike
      def obj.to_time
        '2019-06-28 14:28:48.123 +03'
      end
    }
    its_call(o2) {
      is_expected.to raise_error ArgumentError
    }
  end

  context 'with Time' do
    let(:source) { t('2019-06-28 14:28:48.123 +03') }

    its(:unwrap) { is_expected.to eq source }
    its(:inspect) { is_expected.to eq '#<TimeCalc::Value(2019-06-28 14:28:48 +0300)>' }

    describe '#merge' do
      subject(:merge) { value.method(:merge) }

      its_call(year: 2018) { is_expected.to ret vt('2018-06-28 14:28:48.123 +03') }

      describe 'source symoblic timezone preservation' do
        subject { merge.(year: 2018) }

        # Without zone specification, it will have "system" zone, on my machine:
        #   Time.parse('2019-06-28 14:28:48.123').zone => "EEST"
        let(:source) { t('2019-06-28 14:28:48.123') }

        its(:'unwrap.zone') { is_expected.to eq source.zone }
      end
    end

    describe '#truncate' do
      subject { value.method(:truncate) }

      its_call(:month) { is_expected.to ret vt('2019-06-01 00:00:00 +03') }
      its_call(:hour) { is_expected.to ret vt('2019-06-28 14:00:00 +03') }
      its_call(:sec) { is_expected.to ret vt('2019-06-28 14:28:48 +03') }
    end

    # Just basic "if it works" check. For comprehensive math correctness checks see math_spec.rb
    describe '#+' do
      subject { value.method(:+) }

      its_call(1, :year) { is_expected.to ret vt('2020-06-28 14:28:48.123 +03') }
      its_call(1, :month) { is_expected.to ret vt('2019-07-28 14:28:48.123 +03') }
      its_call(1, :hour) { is_expected.to ret vt('2019-06-28 15:28:48.123 +03') }
    end

    describe '#-' do
      subject { value.method(:-) }

      its_call(1, :year) { is_expected.to ret vt('2018-06-28 14:28:48.123 +03') }
      its_call(1, :month) { is_expected.to ret vt('2019-05-28 14:28:48.123 +03') }
      its_call(1, :hour) { is_expected.to ret vt('2019-06-28 13:28:48.123 +03') }

      context 'with other time' do
        subject { value - t('2018-06-28 14:28:48.123 +03') }

        it { is_expected.to be_kind_of(TimeCalc::Diff) }
      end
    end

    describe '#floor' do
      subject { value.method(:floor) }

      its_call(:month) { is_expected.to ret vt('2019-06-01 00:00:00 +03') }
    end

    describe '#ceil' do
      subject { value.method(:ceil) }

      its_call(:month) { is_expected.to ret vt('2019-07-01 00:00:00 +03') }
      its_call(:day) { is_expected.to ret vt('2019-06-29 00:00:00 +03') }
    end

    describe '#round' do
      subject { value.method(:round) }

      its_call(:month) { is_expected.to ret vt('2019-07-01 00:00:00 +03') }
      its_call(:hour) { is_expected.to ret vt('2019-06-28 14:00:00 +03') }
    end

    describe '#to' do
      subject { value.to(t('2019-07-01')) }

      it {
        is_expected
          .to be_a(TimeCalc::Sequence)
          .and have_attributes(from: value, to: vt('2019-07-01'), step: nil)
      }
    end

    describe '#step' do
      subject { value.step(3, :days) }

      it {
        is_expected
          .to be_a(TimeCalc::Sequence)
          .and have_attributes(from: value, step: [3, :days])
      }
    end

    if RUBY_VERSION >= '2.6'
      require 'tzinfo'
      context 'with real time zones' do
        let(:zone) { TZInfo::Timezone.get('Europe/Zagreb') }
        let(:source) { Time.new(2019, 7, 5, 14, 30, 18, zone) }

        it 'preserves zone' do # rubocop:disable RSpec/MultipleExpectations
          expect(value.merge(month: 10).unwrap.zone).to eq zone
          expect(value.+(1, :hour).unwrap.zone).to eq zone
          expect(value.+(1, :month).unwrap.zone).to eq zone
          expect(value.+(1, :year).unwrap.zone).to eq zone
          expect(value.floor(:year).unwrap.zone).to eq zone
        end

        it 'works well over DST' do # rubocop:disable RSpec/MultipleExpectations
          t1 = Time.new(2019, 10, 26, 14, 30, 12, TZInfo::Timezone.get('Europe/Kiev'))
          t2 = Time.new(2019, 10, 27, 14, 30, 12, TZInfo::Timezone.get('Europe/Kiev'))
          expect(TimeCalc.(t1).+(1, :day)).to eq t2
          expect(TimeCalc.(t2).-(1, :day)).to eq t1
        end
      end
    end
  end

  context 'with Date' do
    let(:source) { d('2019-06-28') }

    its(:unwrap) { is_expected.to eq source }
    its(:inspect) { is_expected.to eq '#<TimeCalc::Value(2019-06-28)>' }

    describe '#merge' do
      subject { value.method(:merge) }

      its_call(year: 2018) { is_expected.to ret vd('2018-06-28') }
    end

    describe '#truncate' do
      subject { value.method(:truncate) }

      its_call(:month) { is_expected.to ret vd('2019-06-01') }
      its_call(:hour) { is_expected.to ret vd('2019-06-28') }
      its_call(:sec) { is_expected.to ret vd('2019-06-28') }
    end

    describe '#+' do
      subject { value.method(:+) }

      its_call(1, :year) { is_expected.to ret vd('2020-06-28') }
      its_call(1, :month) { is_expected.to ret vd('2019-07-28') }
      its_call(1, :hour) { is_expected.to ret vd('2019-06-28') }
    end
  end

  context 'with DateTime' do
    let(:source) { dt('2019-06-28 14:28:48.123 +03') }

    its(:unwrap) { is_expected.to eq source }
    its(:inspect) { is_expected.to eq '#<TimeCalc::Value(2019-06-28T14:28:48+03:00)>' }

    describe '#merge' do
      subject { value.method(:merge) }

      its_call(year: 2018) { is_expected.to ret vdt('2018-06-28 14:28:48.123 +03') }
    end

    describe '#truncate' do
      subject { value.method(:truncate) }

      its_call(:month) { is_expected.to ret vdt('2019-06-01 00:00:00 +03') }
      its_call(:hour) { is_expected.to ret vdt('2019-06-28 14:00:00 +03') }
      its_call(:sec) { is_expected.to ret vdt('2019-06-28 14:28:48 +03') }
    end

    describe '#+' do
      subject { value.method(:+) }

      its_call(1, :year) { is_expected.to ret vdt('2020-06-28 14:28:48.123 +03') }
      its_call(1, :month) { is_expected.to ret vdt('2019-07-28 14:28:48.123 +03') }
      its_call(1, :hour) { is_expected.to ret vdt('2019-06-28 15:28:48.123 +03') }
    end
  end
end
