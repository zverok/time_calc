# frozen_string_literal: true

RSpec.describe TimeCalc::Diff do
  subject(:diff) { described_class.new(t('2020-06-12 12:28 +03'), t('2019-06-01 14:50 +03')) }

  its(:inspect) { is_expected.to eq '#<TimeCalc::Diff(2020-06-12 12:28:00 +0300 − 2019-06-01 14:50:00 +0300)>' }

  describe '#divmod' do
    subject { diff.method(:divmod) }

    its_call(1, :hour) { is_expected.to ret [9045, t('2020-06-12 11:50 +03')] }
    its_call(1, :week) { is_expected.to ret [53, t('2020-06-06 14:50 +03')] }
    its_call(1, :day) { is_expected.to ret [376, t('2020-06-11 14:50 +03')] }
    its_call(1, :month) { is_expected.to ret [12, t('2020-06-01 14:50 +03')] }
    its_call(1, :year) { is_expected.to ret [1, t('2020-06-01 14:50 +03')] }

    its_call(:month) { is_expected.to ret [12, t('2020-06-01 14:50 +03')] }

    its_call(5, :months) { is_expected.to ret [2, t('2020-04-01 14:50 +03')] }

    context 'when negative' do
      let(:diff) { described_class.new(t('2019-06-01 14:50 +03'), t('2020-06-12 12:28 +03')) }

      its_call(1, :year) { is_expected.to ret [-1, t('2019-06-12 12:28 +03')] }
    end

    context 'with Date' do
      let(:diff) { described_class.new(d('2020-06-12'), d('2019-06-01')) }

      # its_call(1, :hour) { is_expected.to ret [9045, t('2020-06-12 11:50 +03')] }
      its_call(1, :week) { is_expected.to ret [53, d('2020-06-06')] }
      its_call(1, :day) { is_expected.to ret [377, d('2020-06-12')] }
      its_call(1, :month) { is_expected.to ret [12, d('2020-06-01')] }
      its_call(1, :year) { is_expected.to ret [1, d('2020-06-01')] }
    end

    context 'with DateTime' do
      let(:diff) { described_class.new(dt('2020-06-12 12:28 +03'), dt('2019-06-01 14:50 +03')) }

      its_call(1, :hour) { is_expected.to ret [9045, dt('2020-06-12 11:50 +03')] }
      its_call(1, :week) { is_expected.to ret [53, dt('2020-06-06 14:50 +03')] }
      its_call(1, :day) { is_expected.to ret [376, dt('2020-06-11 14:50 +03')] }
      its_call(1, :month) { is_expected.to ret [12, dt('2020-06-01 14:50 +03')] }
      its_call(1, :year) { is_expected.to ret [1, dt('2020-06-01 14:50 +03')] }
    end

    context 'with different types' do
      let(:diff) { described_class.new(t('2020-06-12 12:28 +05'), d('2019-06-01')) }

      its_call(1, :hour) { is_expected.to ret [9060, t('2020-06-12 12:00 +05')] }
      its_call(1, :day) { is_expected.to ret [377, t('2020-06-12 00:00 +05')] }
      its_call(1, :week) { is_expected.to ret [53, t('2020-06-06 00:00 +05')] }
      its_call(1, :month) { is_expected.to ret [12, t('2020-06-01 00:00 +05')] }
      its_call(1, :year) { is_expected.to ret [1, t('2020-06-01 00:00 +05')] }
    end

    if RUBY_VERSION >= '2.6'
      require 'tzinfo'

      context 'when calculated over DST' do
        context 'when autumn' do
          let(:before) { Time.new(2019, 10, 26, 14, 30, 12, TZInfo::Timezone.get('Europe/Kiev')) }
          let(:after) { Time.new(2019, 10, 27, 14, 30, 12, TZInfo::Timezone.get('Europe/Kiev')) }

          it { expect(described_class.new(after, before).div(:day)).to eq 1 }
          it { expect(described_class.new(before, after).div(:day)).to eq(-1) }
        end

        context 'when spring' do
          let(:before) { Time.new(2019, 3, 30, 14, 30, 12, TZInfo::Timezone.get('Europe/Kiev')) }
          let(:after) { Time.new(2019, 3, 31, 14, 30, 12, TZInfo::Timezone.get('Europe/Kiev')) }

          it { expect(described_class.new(after, before).div(:day)).to eq 1 }
          it { expect(described_class.new(before, after).div(:day)).to eq(-1) }
        end
      end
    end
  end

  describe '#div' # tested by #divmod, in fact

  describe '#modulo' do
    subject { diff.method(:modulo) }

    its_call(5, :months) { is_expected.to ret t('2020-04-01 14:50 +03') }
  end

  describe '#<unit>' do
    its(:days) { is_expected.to eq 376 }
  end

  describe '#factorize' do
    subject { diff.method(:factorize) }

    its_call { is_expected.to ret(year: 1, month: 0, week: 1, day: 3, hour: 21, min: 38, sec: 0) }
    its_call(max: :month) { is_expected.to ret(month: 12, week: 1, day: 3, hour: 21, min: 38, sec: 0) }
    its_call(max: :month, min: :hour) { is_expected.to ret(month: 12, week: 1, day: 3, hour: 21) }
    its_call(max: :month, min: :hour, weeks: false) { is_expected.to ret(month: 12, day: 10, hour: 21) }

    context 'when zeroes' do
      let(:diff) { described_class.new(t('2019-06-12 12:28 +03'), t('2019-06-01 14:50 +03')) }

      its_call { is_expected.to ret(year: 0, month: 0, week: 1, day: 3, hour: 21, min: 38, sec: 0) }
      its_call(zeroes: false) { is_expected.to ret(week: 1, day: 3, hour: 21, min: 38, sec: 0) }
    end

    context 'with Date' do
      let(:diff) { described_class.new(d('2019-06-12'), t('2019-06-01 14:50 +03')) }

      its_call { is_expected.to ret(year: 0, month: 0, week: 1, day: 3, hour: 9, min: 10, sec: 0) }
    end

    context 'when negative' do
      let(:diff) { -super() }

      its_call { is_expected.to ret(year: -1, month: 0, week: -1, day: -3, hour: -21, min: -38, sec: 0) }
    end
  end
end
