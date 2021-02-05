# frozen_string_literal: true

class TimeCalc
  # @private
  # Tries to encapsulate all the differences between Time, Date, DateTime
  module Types
    extend self

    ATTRS = {
      'Time' => %i[year month day hour min sec subsec utc_offset],
      'Date' => %i[year month day],
      'DateTime' => %i[year month day hour min sec sec_fraction zone],
      'ActiveSupport::TimeWithZone' => %i[year month day hour min sec sec_fraction time_zone]
    }.freeze

    # @private
    # Because AS::TimeWithZone so frigging smart that it returns "Time" from redefined class name.
    CLASS_NAME = Class.instance_method(:name)

    def compatible?(v1, v2)
      [v1, v2].all?(Date) || [v1, v2].all?(Time)
    end

    def compare(v1, v2)
      compatible?(v1, v2) ? v1 <=> v2 : v1.to_time <=> v2.to_time
    end

    def convert(v, klass)
      return v if v.instance_of?(klass)

      v.public_send("to_#{klass.name.downcase}")
    end

    def merge_time(value, **attrs)
      _merge(value, **attrs)
        .tap { |h| h[:sec] += h.delete(:subsec) }
        .then { |h| fix_time_zone(h, value) }
        .values.then { |components| Time.new(*components) }
    end

    def merge_date(value, **attrs)
      _merge(value, **attrs).values.then { |components| Date.new(*components) }
    end

    def merge_datetime(value, **attrs)
      # When we truncate, we use :subsec key as a sign to zeroefy second fractions
      attrs[:sec_fraction] ||= attrs.delete(:subsec) if attrs.key?(:subsec)

      _merge(value, **attrs)
        .tap { |h| h[:sec] += h.delete(:sec_fraction) }
        .values.then { |components| DateTime.new(*components) }
    end

    def merge_activesupport__timewithzone(value, **attrs)
      # You'd imagine we should be able to use just value.change(...) ActiveSupport's API here...
      # But it is not available if you don't require all the core_ext's of Time, so I decided to
      # be on the safe side and use similar approach everywhere.

      # When we truncate, we use :subsec key as a sign to zeroefy second fractions
      attrs[:sec_fraction] ||= attrs.delete(:subsec) if attrs.key?(:subsec)

      _merge(value, **attrs)
        .then { |components|
          zone = components.delete(:time_zone)
          components.merge!(mday: components.delete(:day), mon: components.delete(:month))
          zone.__send__(:parts_to_time, components, value)
        }
    end

    private

    REAL_TIMEZONE = ->(z) { z.respond_to?(:utc_to_local) } # Ruby 2.6 real timezones

    def fix_time_zone(attrs, origin)
      case origin.zone
      when nil, '' # "" is JRuby's way to say "no zone known"
        attrs
      when String
        # Y U NO Hash#except, Ruby???
        attrs.slice(*attrs.keys.-([:utc_offset])) # Then it would be default, then it would set system's zone
      when REAL_TIMEZONE
        attrs.merge(utc_offset: origin.zone) # When passed in place of utc_offset, timezone object becomes Time's zone
      end
    end

    def _merge(value, attrs)
      attr_names = ATTRS.fetch(CLASS_NAME.bind(value.class).call)
      attr_names.to_h { |u| [u, value.public_send(u)] }.merge(**attrs.slice(*attr_names))
    end
  end
end
