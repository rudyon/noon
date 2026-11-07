module NoonC
  module AST
    alias Node = Function | NoonInt

    struct Function
      property name, body

      def initialize(@name : String, @body : Array(Node))
      end
    end

    struct NoonInt
      property value

      def initialize(@value : Int32)
      end
    end
  end
end
