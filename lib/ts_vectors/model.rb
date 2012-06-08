module TsVectors
  module Model
    extend ActiveSupport::Concern

    included do
    end

    class Attribute
      def initialize(name, options = {})
        options.assert_valid_keys(:normalize)
        @name, @options = name, options
      end

      def parse_values(string)
        if string
          values = string.scan(/(?:([^'\s,]+)|'([^']+)')\s*/u).flatten
          values.reject! { |v| v.blank? }
          values
        else
          []
        end
      end

      def normalize_values(values)
        values = [values] unless values.is_a?(Enumerable)
        values = values.map { |v| normalize(v) }
        values.compact!
        values
      end

      def normalize(value)
        if value
          if (normalize = @options[:normalize])
            value = normalize.call(value)
          else
            value = value.strip.downcase
          end
          if value.blank?
            nil
          elsif value =~ /\s/
            %('#{value}')
          else
            value
          end
        end
      end

      attr_reader :name
      attr_reader :options
    end

    module ClassMethods

      def ts_vector(attribute, options = {})
        attr = Attribute.new(attribute, options)

        @ts_vectors ||= {}
        @ts_vectors[attribute] = attr

        scope "with_all_#{attribute}", lambda { |values|
          values = attr.normalize_values(values)
          if values.any?
            where("#{attribute} @@ to_tsquery('simple', ?)", values.join(' & '))
          else
            where('false')
          end
        }

        scope "with_any_#{attribute}", lambda { |values|
          values = attr.normalize_values(values)
          if values.any?
            where("#{attribute} @@ to_tsquery('simple', ?)", values.join(' | '))
          else
            where('false')
          end
        }

        scope "without_all_#{attribute}", lambda { |values|
          values = attr.normalize_values(values)
          if values.any?
            where("#{attribute} @@ (!! to_tsquery('simple', ?))", values.join(' & '))
          else
            where('false')
          end
        }

        scope "without_any_#{attribute}", lambda { |values|
          values = attr.normalize_values(values)
          if values.any?
            where("#{attribute} @@ (!! to_tsquery('simple', ?))", values.join(' | '))
          else
            where('false')
          end
        }

        scope "order_by_#{attribute}_rank", lambda { |values, direction = nil|
          direction = 'DESC' unless %w(asc ascending desc descending).include?(direction.try(:downcase))
          values = attr.normalize_values(values)
          if values.any?
            order(sanitize_sql_array([
              "ts_rank(#{attribute}, to_tsquery('simple', ?)) #{direction}", values.join(' | ')]))
          else
            order('false')
          end
        }

        define_method(attribute) do
          attr.parse_values(read_attribute(attribute))
        end

        define_method("#{attribute}=") do |values|
          values = attr.normalize_values(values)
          if values.any?
            write_attribute(attribute, values.join(' '))
          else
            write_attribute(attribute, nil)
          end
        end
      end

    end

  end
end
