module TsVectors

  class Attribute
    def initialize(name, options = {})
      options.assert_valid_keys(:normalize, :configuration, :format)
      @name, @options = name, options
      if (config = @options[:configuration])
        @configuration = config
      else
        @configuration = 'simple'
      end
      if (format = @options[:format])
        @format = format.to_sym
      else
        @format = :text
      end
    end

    def format_operand
      @operand ||= begin
        config = @configuration
        if @format == :text
          "to_tsvector('#{config}', #{@name})"
        else
          @name
        end
      end
    end

    def format_query
      @query ||= "to_tsquery('#{@configuration}', ?)"
    end

    def serialize_values(values)
      if values and values.length > 0
        values.join(' ')
      else
        nil
      end
    end

    def parse_values(string)
      if string
        values = string.scan(/(?:([^'\s,]+(?::\d+)?)|'([^']+)(?::\d+)?')\s*/u).flatten
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
    attr_reader :format
    attr_reader :configuration
  end

end