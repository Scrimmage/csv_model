using CSVModel::Extensions

module CSVModel
  class Model

    attr_reader :data, :header, :options, :parse_error, :rows

    def initialize(data, options = {})
      @data = data
      @rows = []
      @options = options
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

    private

    def parse_data
      return if @parsed
      @parsed = true

      begin
        keys = Set.new

        CSV.parse(data, { col_sep: "\t" }).each_with_index do |row, index|
          if index == 0
            @header = HeaderRow.new(row, options)
          end

          if row.size != header.column_count
            raise ParseError.new("Each row should have exactly #{header.column_count} columns. Error on row #{index + 1}.")
          end

          # TODO: Should we keep this?
          # if index > (limit - 1)
          #   raise ParseError.new("You can only import #{limit} records at a time. Please split your import into multiple parts.")
          # end

          if index > 0 
            row = Row.new(header, row)
            row.mark_as_duplicate unless keys.add?(row.key)
            @rows << row
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
  end

end
