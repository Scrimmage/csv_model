using CSVModel::Extensions

module CSVModel
  class Row
    attr_reader :data, :header, :marked_as_duplicate, :options

    def initialize(header, data, options = {})
      @header = header
      @data = data
      @options = options
    end

    def index(value)
      index = column_index(value) || value
      data[index] if index.is_a?(Fixnum) && index >= 0
    end
    alias_method :[], :index

    def errors
      errors = []
      errors << duplicate_row_error if marked_as_duplicate?
      errors << model_instance.errors if !model_instance.valid?
      errors.flatten
    end

    def key
      cols = primary_key_columns
      if cols.one?
        index(cols.first.key)
      elsif cols.any?
        cols.collect { |x| index(x.key) }
      else
        data
      end
    end

    def marked_as_duplicate?
      !!marked_as_duplicate
    end

    def mark_as_duplicate
      @marked_as_duplicate = true
    end

    def status
      model_instance.status
    end

    def valid?
      errors.empty?
    end

    [:errors, :status, :valid?].each do |method_name|
      method = instance_method(method_name)
      define_method(method_name) do |*args, &block|
        process_row
        method.bind(self).(*args, &block)
      end
    end

    private

    def all_attributes
      @all_attributes ||= column_attributes_with_values(columns)
    end

    def columns
      header.columns
    end

    def column_attributes_with_values(cols)
      Hash[cols.collect { |col| [col.model_attribute, index(col.key)] }]
    end

    def column_index(key)
      header.column_index(key)
    end

    def duplicate_row_error
      names = primary_key_columns.collect { |x| x.name }
      names.any? ? "Duplicate #{names.join(', ')}" : "Duplicate row"
    end

    def is_dry_run?
      options[:dry_run] || false
    end

    def model
      option(:model)
    end

    def model_instance
      @model_instance ||= begin
        x = inherit_or_delegate(:find_row_model, key_attributes) 
        x ||= inherit_or_delegate(:new_row_model, key_attributes)
        x = CSVModel::ObjectWithStatusSnapshot.new(x)
      end
    end

    def key_attributes
      cols = primary_key_columns.any? ? primary_key_columns : columns
      @key_attributes ||= column_attributes_with_values(cols)
    end


    def primary_key_columns
      header.primary_key_columns
    end

    def process_row
      model_instance.assign_attributes(all_attributes)
      model_instance.mark_as_duplicate if marked_as_duplicate?
      model_instance.save(dry_run: is_dry_run?)
    end

    private

    def inherit_or_delegate(method, *args)
      try(method, *args) || model.try(method, *args)
    end

    def option(key, default = nil)
      options.try(:[], key) || options.try(key) || default
    end

  end
end