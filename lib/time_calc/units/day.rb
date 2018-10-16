class TimeCalc
  module Units
    # @private
    class Day < Simple
      private

      def _advance(tm, steps)
        fix_dst(super(tm, steps), tm)
      end

      def _decrease(tm, steps)
        fix_dst(super(tm, steps), tm)
      end

      # :nocov: - somehow Travis env thinks other things about DST
      def fix_dst(res, src)
        return res unless res.is_a?(Time)

        if res.dst? && !src.dst?
          TimeCalc.(res).-(1, :hour)
        elsif !res.dst? && src.dst?
          TimeCalc.(res).+(1, :hour)
        else
          res
        end
      end
      # :nocov:
    end
  end
end
