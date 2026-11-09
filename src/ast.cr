module Noon
  module AST
    alias Node = Function | FFI | Call | Integer32 | NoonString | Symbol
    alias Argument = Call | Integer32 | NoonString | Symbol

    struct Function
      property name, params, body

      def initialize(@name : String, @params : Array(Symbol), @body : Array(Node))
      end
    end

    struct FFI
      property string, function

      def initialize(@string : NoonString, @function : Function)
      end
    end

    struct Call
      property name, args

      def initialize(@name : String, @args : Array(Argument))
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

    struct Symbol
      property name

      def initialize(@name : String)
      end
    end
  end
end
