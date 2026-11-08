module Noon
  module AST
    alias Node = Function | UInteger8

    struct Function
      property name, body

      def initialize(@name : String, @body : Array(Node))
      end
    end

    struct UInteger8
      property value

      def initialize(@value : UInt8)
      end
    end
  end
end
