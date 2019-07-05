# frozen_string_literal: true

class TimeCalc
  # @private
  module DST
    extend self

    def fix_value(val, origin)
      case (c = compare(origin.unwrap, val.unwrap))
      when nil, 0
        val
      else
        val.+(c, :hour)
      end
    end

    def fix_day_diff(from, to, diff)
      # Just add one day when it is (DST - non-DST)
      compare(from, to) == 1 ? diff + 1 : diff
    end

    private

    # it returns nil if dst? is not applicable to the value
    def is?(tm)
      # it is not something we can reliably process
      return unless tm.respond_to?(:zone) && tm.respond_to?(:dst?)

      # We can't say "it is not DST" (like `Time#dst?` will say), only "It is time without DST info"
      # Empty string is what JRuby does when it doesn't know.
      return if tm.zone.nil? || tm.zone == ''

      # Workaround for: https://bugs.ruby-lang.org/issues/15988
      # In Ruby 2.6, Time with "real" Timezone always return `dst? => true` for some zones.
      # Relates on TZInfo API (which is NOT guaraneed to be present, but practically should be)
      tm.zone.respond_to?(:dst?) ? tm.zone.dst?(tm) : tm.dst?
    end

    def compare(v1, v2)
      dst1 = is?(v1)
      dst2 = is?(v2)
      case
      when [dst1, dst2].any?(&:nil?)
        nil
      when dst1 == dst2
        0
      when dst1 # and !dst2
        1
      else # !dst1 and dst2
        -1
      end
    end
  end
end
