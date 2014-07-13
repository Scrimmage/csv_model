using CSVModel::Extensions

module CSVModel
  class Row
    include Utilities::Options

    attr_reader :data, :header, :model_index, :marked_as_duplicate

    def initialize(header, data, model_index, options = {})
      @header = header
      @data = data
      @model_index = model_index
      @options = options
    end

    alias_method :csv_index, :model_index

    def index(value)
      index = column_index(value) || value
      data[index] if index.is_a?(Fixnum) && index >= 0
    end
    alias_method :[], :index

    def errors
      errors = []
      errors << duplicate_row_error if is_dry_run? && marked_as_duplicate?
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

    def map_all_attributes(attrs)
      attrs
    end

    def map_key_attributes(attrs)
      attrs
    end

    def marked_as_duplicate?
      !!marked_as_duplicate
    end

    def mark_as_duplicate
      @marked_as_duplicate = true
    end

    def process_row
      return model_instance.status if @processed
      @processed = true

      model_instance.assign_attributes(all_attributes)
      model_instance.mark_as_duplicate if marked_as_duplicate?
      model_instance.save(dry_run: is_dry_run?)
      model_instance.status
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
      @all_attributes ||= model_mapper.map_all_attributes(column_attributes_with_values(columns))
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
      option(:dry_run, false)
    end

    def model_adaptor
      CSVModel::RowActiveRecordAdaptor
    end

    def model_finder
      option(:row_model_finder)
    end

    def model_instance
      @model_instance ||= begin
        x = inherit_or_delegate(:find_row_model, key_attributes) 
        x ||= inherit_or_delegate(:new_row_model, key_attributes)
        x = model_adaptor.new(x)
      end
    end

    def model_mapper
      option(:row_model_mapper, self)
    end

    def key_attributes
      cols = primary_key_columns.any? ? primary_key_columns : columns
      @key_attributes ||= model_mapper.map_key_attributes(column_attributes_with_values(cols))
    end

    def primary_key_columns
      header.primary_key_columns
    end

    private

    def inherit_or_delegate(method, *args)
      try(method, *args) || model_finder.try(method, *args)
    end

  end
end
