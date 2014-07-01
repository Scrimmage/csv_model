using CSVModel::Extensions

module CSVModel
  class Column
    include Utilities::Options

    attr_reader :name

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

  end
end
