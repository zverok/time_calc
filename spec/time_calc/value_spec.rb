require 'time_calc/value'

RSpec.describe TimeCalc::Value do
  subject(:value) { described_class.new(time) }
  let(:time) { t('2019-06-28 14:28:48.123 +03') }

  its(:to_time) { is_expected.to eq time }
  its(:inspect) { is_expected.to eq '#<TimeCalc::Value(2019-06-28 14:28:48 +0300)>' }

  def vt(str)
    TimeCalc::Value.new(t(str))
  end

  describe '#[]' do
    subject { value.method(:[]) }

    its_call(:year) { is_expected.to ret 2019 }
  end

  describe '#values_at' do
    subject { value.method(:values_at) }

    its_call(:year, :month, :day) { is_expected.to ret [2019, 6, 28] }
  end

  its(:to_h) {
    is_expected.to eq(
      year: 2019, month: 6, day: 28, hour: 14, min: 28, sec: 48, subsec: 123/1000r
    )
  }

  describe '#merge' do
    subject { value.method(:merge) }

    its_call(year: 2018) { is_expected.to ret vt('2018-06-28 14:28:48.123 +03') }
  end

  describe '#truncate' do
    subject { value.method(:truncate) }

    its_call(:month) { is_expected.to ret vt('2019-06-01 00:00:00 +03') }
    its_call(:hour) { is_expected.to ret vt('2019-06-28 14:00:00 +03') }
    its_call(:sec) { is_expected.to ret vt('2019-06-28 14:28:48 +03') }
  end

  # Just basic "if it works" check. For comprehensive math correctness checks see math_spec.rb
  describe '#+' do
    subject { ->(*args) { value.+(*args).to_time } }

    its_call(1, :year) { is_expected.to ret t('2020-06-28 14:28:48.123 +03') }
    its_call(1, :month) { is_expected.to ret t('2019-07-28 14:28:48.123 +03') }
    its_call(1, :hour) { is_expected.to ret t('2019-06-28 15:28:48.123 +03') }
  end

  describe '#-' do
    subject { ->(*args) { value.-(*args).to_time } }

    its_call(1, :year) { is_expected.to ret t('2018-06-28 14:28:48.123 +03') }
    its_call(1, :month) { is_expected.to ret t('2019-05-28 14:28:48.123 +03') }
    its_call(1, :hour) { is_expected.to ret t('2019-06-28 13:28:48.123 +03') }
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
end