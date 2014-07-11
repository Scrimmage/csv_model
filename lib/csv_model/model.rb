using CSVModel::Extensions

module CSVModel
  class Model
    include Utilities::Options

    attr_reader :data, :header, :keys, :parse_error, :rows

    def initialize(data, options = {})
      @data = data
      @rows = []
      @options = options
      @keys = Set.new
    end

    def row_count
      rows.count
    end

    def structure_errors
      return [parse_error] if parse_error
      return header.errors if !header.valid?
      []
    end

    def structure_valid?
      parse_error.nil? && header.valid?
    end

    instance_methods(false).each do |method_name|
      method = instance_method(method_name)
      define_method(method_name) do |*args, &block|
        parse_data
        method.bind(self).(*args, &block)
      end
    end

    protected

    def create_header_row(row)
      header_class.new(row, options)
    end

    def create_row(row)
      row = row_class.new(header, row, options)
      row.mark_as_duplicate if is_duplicate_key?(row.key)
      row
    end

    def detect_duplicate_rows?
      option(:detect_duplicate_rows, true)
    end

    def header_class
      option(:header_class, HeaderRow)
    end

    def is_duplicate_key?(value)
      return false if !detect_duplicate_rows? || value.nil? || value == "" || (value.is_a?(Array) && value.all_values_blank?)
      !keys.add?(value)
    end

    def parse_data
      return if @parsed
      @parsed = true

      begin
        CSV.parse(data, { col_sep: "\t" }).each_with_index do |row, index|
          if index == 0
            @header = create_header_row(row)
          end

          if row.size != header.column_count
            raise ParseError.new("Each row should have exactly #{header.column_count} columns. Error on row #{index + 1}.")
          end

          # TODO: Should we keep this?
          # if index > (limit - 1)
          #   raise ParseError.new("You can only import #{limit} records at a time. Please split your import into multiple parts.")
          # end

          if index > 0 
            @rows << create_row(row)
          end
        end
      rescue CSV::MalformedCSVError => e
        @parse_error = "The data could not be parsed. Please check for formatting errors: #{e.message}"
      rescue ParseError => e
        @parse_error = e.message
      rescue Exception => e
        @parse_error = "An unexpected error occurred. Please try again or contact support if the issue persists: #{e.message}"
      end
    end

    def row_class
      option(:row_class, Row)
    end

  end
end
