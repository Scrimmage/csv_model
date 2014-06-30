using CSVModel::Extensions

module CSVModel
  class HeaderRow

    attr_reader :data, :options

    def initialize(data, options = {})
      @data = data
      @options = options
    end

    def columns
      @columns ||= data.collect { |x| Column.new(x) }
    end

    def column_count
      columns.count
    end

    def column_index(key)
      column_keys.index(key.to_column_key)
    end

    def errors
      duplicate_column_errors + illegal_column_errors + missing_column_errors
    end

    # TODO: Remove? Not currently used.
    def has_column?(key)
      !column_index(key).nil?
    end

    def primary_key_columns
      @primary_key_columns ||= columns.select { |x| primary_key_column_names.include?(x.name) }
    end

    def valid?
      has_required_columns? && !has_duplicate_columns? && !has_illegal_columns?
    end

    protected

    def column_keys
      @column_keys ||= columns.collect { |x| x.key }
    end

    def column_map
      @column_map ||= Hash[columns.collect { |x| [x.key, x] }]
    end

    def column_name(column_key)
      data.find { |entry| entry.to_column_key == column_key }
    end

    def duplicate_column_errors
      duplicate_column_names.collect { |name| "Multiple columns found for #{name}, column headings must be unique" }
    end

    def duplicate_column_names
      data.collect { |x| x.to_column_key }
        .inject(Hash.new(0)) { |counts, key| counts[key] += 1; counts }
        .select { |key, count| count > 1 }
        .collect { |key, count| column_name(key) }
    end

    def has_duplicate_columns?
      data.count != column_map.keys.count
    end

    def has_illegal_columns?
      illegal_column_keys.any?
    end

    def has_required_columns?
      missing_column_keys.empty?
    end

    def illegal_column_errors
      illegal_column_names.collect { |name| "Unknown column #{name}" }
    end

    def illegal_column_keys
      legal_column_names.any? ? column_keys - legal_column_keys : []    
    end

    def illegal_column_names
      illegal_column_keys.collect { |key| column_name(key) }
    end

    def legal_column_names
      option(:legal_columns)
    end

    def legal_column_keys
      legal_column_names.collect { |x| x.to_column_key }
    end

    def missing_column_errors
      missing_column_names.collect { |name| "Missing column #{name}" }
    end

    def missing_column_keys
      required_column_keys - column_keys
    end

    def missing_column_names
      missing_column_keys.collect { |key| required_column_name(key) }
    end

    def primary_key_column_names
      option(:primary_key)
    end

    def required_column_keys
      required_column_names.collect { |x| x.to_column_key }
    end

    def required_column_name(column_key)
      required_column_names.find { |entry| entry.to_column_key == column_key }
    end

    def required_column_names
      option(:required_columns)
    end

    private
    
    def option(key)
      options.try(:[], key) || options.try(key) || []
    end

  end
end
