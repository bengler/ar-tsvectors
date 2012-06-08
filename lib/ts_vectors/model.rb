module TsVectors
  module Model
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods

      def ts_vector(attribute, options = {})
        attr = Attribute.new(attribute, options)

        @ts_vectors ||= {}
        @ts_vectors[attribute] = attr

        scope "with_all_#{attribute}", lambda { |values|
          values = attr.normalize_values(values)
          if values.any?
            where("#{attr.format_operand} @@ #{attr.format_query}", values.join(' & '))
          else
            where('false')
          end
        }

        scope "with_any_#{attribute}", lambda { |values|
          values = attr.normalize_values(values)
          if values.any?
            where("#{attr.format_operand} @@ #{attr.format_query}", values.join(' | '))
          else
            where('false')
          end
        }

        scope "without_all_#{attribute}", lambda { |values|
          values = attr.normalize_values(values)
          if values.any?
            where("#{attr.format_operand} @@ (!! #{attr.format_query})", values.join(' & '))
          else
            where('false')
          end
        }

        scope "without_any_#{attribute}", lambda { |values|
          values = attr.normalize_values(values)
          if values.any?
            where("#{attr.format_operand} @@ (!! #{attr.format_query})", values.join(' | '))
          else
            where('false')
          end
        }

        scope "order_by_#{attribute}_rank", lambda { |values, direction = nil|
          direction = 'DESC' unless %w(asc ascending desc descending).include?(direction.try(:downcase))
          values = attr.normalize_values(values)
          if values.any?
            order(sanitize_sql_array([
              "ts_rank(#{attr.format_operand}, #{attr.format_query}) #{direction}", values.join(' | ')]))
          else
            order('false')
          end
        }

        define_method(attribute) do
          attr.parse_values(read_attribute(attribute))
        end

        define_method("#{attribute}=") do |values|
          write_attribute(attribute, attr.serialize_values(
            attr.normalize_values(values)))
        end
      end

    end

  end
end
