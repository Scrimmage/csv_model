using CSVModel::Extensions

module CSVModel
  module Utilities
    module Options

      attr_reader :options

      def option(key, default = nil)
        value = options.try(:[], key) 
        value = options.try(key) if value.nil?
        value = default if value.nil?
        value
      end

    end
  end
end
