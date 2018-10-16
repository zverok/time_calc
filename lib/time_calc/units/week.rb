class TimeCalc
  module Units
    # @private
    class Week < Simple
      def floor(tm, span = 1)
        span == 1 or
          raise NotImplementedError, 'For now, week only can floor to one'

        f = TimeCalc.(tm).floor(:day)
        extra_days = tm.wday.zero? ? 6 : tm.wday - 1
        TimeCalc.(f).-(extra_days, :day)
      end

      def to_seconds(sz = 1)
        Units.get(:day).to_seconds(sz * 7)
      end

      private

      def _advance(tm, steps)
        TimeCalc.(tm).+(steps * 7, :day)
      end

      def _decrease(tm, steps)
        TimeCalc.(tm).-(steps * 7, :day)
      end
    end
  end
end
