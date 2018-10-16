class TimeCalc
  module Units
    # @private
    class Month < Base
      private

      def _advance(tm, steps)
        target = tm.month + steps.to_i
        m = (target - 1) % 12 + 1
        dy = (target - 1) / 12
        Util.merge(tm, year: tm.year + dy, month: m)
      end

      def _decrease(tm, steps)
        _advance(tm, -steps)
      end
    end
  end
end
