module CSVModel
  module Extensions

    refine NilClass do
      def try(*args)
        nil
      end
    end

    refine Object do
      def try(*a, &b)
        if a.empty? && block_given?
          yield self
        else
          public_send(*a, &b) if respond_to?(a.first)
        end
      end
    end

    refine String do
      def to_column_key
        downcase.strip
      end

      def underscore
        tr(' ', '_').tr("-", "_")        
      end
    end

    refine Symbol do
      def to_column_key
        to_s.downcase.strip
      end
    end

  end
end
