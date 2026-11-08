module Noon
  module AST
    alias Node = Function | Integer32

    struct Function
      property name, body

      def initialize(@name : String, @body : Array(Node))
      end
    end

    struct Integer32
      property value

      def initialize(@value : Int32)
      end
    end
  end
end
