class TimeCalc
  module Units
    # @private
    class Year < Base
      private

      def _advance(tm, steps)
        Util.merge(tm, year: tm.year + steps.to_i)
      end

      def _decrease(tm, steps)
        Util.merge(tm, year: tm.year - steps.to_i)
      end
    end
  end
end
