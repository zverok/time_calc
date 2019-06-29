RSpec.describe TimeCalc::Diff do
  subject(:diff) { described_class.new(t('2020-06-12 12:28 +03'), t('2019-06-01 14:50 +03')) }

  describe '#divmod' do
    subject { diff.method(:divmod) }

    its_call(1, :hour) { is_expected.to ret [9045, t('2020-06-12 11:50 +03')] }
    its_call(1, :day) { is_expected.to ret [376, t('2020-06-11 14:50 +03')] }
    its_call(1, :month) { is_expected.to ret [12, t('2020-06-01 14:50 +03')] }
    its_call(1, :year) { is_expected.to ret [1, t('2020-06-01 14:50 +03')] }

    its_call(:month) { is_expected.to ret [12, t('2020-06-01 14:50 +03')] }

    context 'when negative'
  end

  describe '#div'
  describe '#modulo'

  describe '#/' do
  end
  describe '#%'
  describe '#factorize' do
    context 'when default'
    context 'when max set'
    context 'with weeks'
  end
end