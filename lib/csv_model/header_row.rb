using CSVModel::Extensions

module CSVModel
  class HeaderRow
    include Utilities::Options

    attr_reader :data

    def initialize(data, options = {})
      @data = data
      @options = options
      validate_options
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
      (duplicate_column_errors + illegal_column_errors + missing_column_errors + missing_key_column_errors).uniq
    end

    def has_column?(key)
      !column_index(key).nil?
    end

    def primary_key_columns
      @primary_key_columns ||= begin
        if has_primary_key? && has_primary_key_columns?
          primary_primary_key_columns
        elsif has_alternate_primary_key? && has_alternate_primary_key_columns?
          alternate_primary_key_columns
        else
          []
        end
      end
    end

    def valid?
      has_required_columns? && has_required_key_columns? && !has_duplicate_columns? && !has_illegal_columns?
    end

    protected

    def alternate_primary_key_columns
      columns.select { |x| alternate_primary_key_column_keys.include?(x.key) }
    end

    def alternate_primary_key_column_keys
      alternate_primary_key_column_names.collect { |x| x.to_column_key }
    end

    def alternate_primary_key_column_names
      option(:alternate_primary_key, [])
    end

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

    def has_alternate_primary_key?
      alternate_primary_key_column_names.any?
    end

    def has_alternate_primary_key_columns?
      missing_alternate_primary_key_column_keys.empty?
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

    def has_required_key_columns?
      !has_primary_key? || (has_primary_key? && has_primary_key_columns?) || (has_alternate_primary_key? && has_alternate_primary_key_columns?)
    end

    def has_primary_key?
      primary_key_column_names.any?
    end

    def has_primary_key_columns?
      missing_primary_key_column_keys.empty?
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
      option(:legal_columns, [])
    end

    def legal_column_keys
      legal_column_names.collect { |x| x.to_column_key }
    end

    def missing_alternate_primary_key_column_keys
      alternate_primary_key_column_keys - column_keys
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

    def missing_primary_key_column_keys
      primary_key_column_keys - column_keys
    end

    def missing_primary_key_column_names
      missing_primary_key_column_keys.collect { |key| primary_key_column_name(key) }
    end

    def missing_key_column_errors
      has_alternate_primary_key? && has_alternate_primary_key_columns? ? [] : primary_key_column_errors
    end

    def primary_primary_key_columns
      columns.select { |x| primary_key_column_keys.include?(x.key) }
    end

    def primary_key_column_errors
      missing_primary_key_column_names.collect { |name| "Missing column #{name}" }
    end

    def primary_key_column_keys
      primary_key_column_names.collect { |x| x.to_column_key }
    end

    def primary_key_column_name(column_key)
      primary_key_column_names.find { |entry| entry.to_column_key == column_key }
    end

    def primary_key_column_names
      option(:primary_key, [])
    end

    def required_column_keys
      required_column_names.collect { |x| x.to_column_key }
    end

    def required_column_name(column_key)
      required_column_names.find { |entry| entry.to_column_key == column_key }
    end

    def required_column_names
      option(:required_columns, [])
    end

    def validate_options
      if !option(:primary_key).nil? && primary_key_column_keys.empty?
        raise ArgumentError.new("The primary_key cannot be be empty.")
      end

      if legal_column_keys.any? && (primary_key_column_keys - legal_column_keys).any?
        raise ArgumentError.new("The primary_key cannot contain columns that are not included in legal_column_keys.")
      end

      if primary_key_column_names.empty? && alternate_primary_key_column_names.any?
        raise ArgumentError.new("The alternate_primary_key cannot be specified if no primary_key is specified.")
      end

      if !option(:alternate_primary_key).nil? && primary_key_column_keys == alternate_primary_key_column_keys
        raise ArgumentError.new("The alternate_primary_key cannot be identical to the primary_key.")
      end

      if legal_column_keys.any? && (alternate_primary_key_column_keys - legal_column_keys).any?
        raise ArgumentError.new("The alternate_primary_key cannot contain columns that are not included in legal_column_keys.")
      end
    end
  end

end
