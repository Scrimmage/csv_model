using CSVModel::Extensions

module CSVModel
  module Utilities
    module Options

      attr_reader :options

      def option(key, default = nil)
        options.try(:[], key) || options.try(key) || default
      end

    end
  end
end
