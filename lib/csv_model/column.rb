using CSVModel::Extensions

module CSVModel
  class Column

    attr_reader :name, :options

    def initialize(name, options = {})
      @name = name
      @options = options
    end

    def is_primary_key?
      option(:primary_key, false)
    end

    def key
      name.to_column_key
    end

    def model_attribute
      key.underscore.to_sym
    end

    private

    def option(key, default)
      options.try(:[], key) || options.try(key) || default
    end

  end
end
