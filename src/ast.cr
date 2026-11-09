module Noon
  module AST
    alias Node = Function | Parameter | FFI | Integer32 | NoonString

    struct Function
      property name, params, body

      def initialize(@name : String, @params : Array(Parameter), @body : Array(Node))
      end
    end

    struct Parameter
      property name

      def initialize(@name : String)
      end
    end

    struct FFI
      property string, function

      def initialize(@string : NoonString, @function : Function)
      end
    end

    struct Integer32
      property value

      def initialize(@value : Int32)
      end
    end

    struct NoonString
      property string

      def initialize(@string : String)
      end
    end
  end
end
