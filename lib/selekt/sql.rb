module Selekt
  module SQL
    module TableReference
      def variable_name
        if elements.last.empty?
          elements.first.text_value
        else
          elements.last.text_value
        end
      end
    end

    module Source
      def variable_name
        if elements.last.empty?
          elements.first.variable_name
        else
          elements.last.variable_name
        end
      end
    end

    module Alias
      def variable_name
        elements.last.text_value
      end
    end
  end
end
