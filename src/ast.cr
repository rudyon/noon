module Noon
  module AST
    alias Node = If | Function | Parameter | FFI | Call | UInteger32 | NoonString | Symbol | TypeAnnotation
    alias Expression = Call | UInteger32 | NoonString | Symbol

    struct If
      property condition, body

      def initialize(@condition : Condition, @body : Array(Node))
      end
    end

    struct Function
      property name, params, type, body

      def initialize(@name : String, @params : Array(Parameter), @type : TypeAnnotation, @body : Array(Node))
      end
    end

    struct Parameter
      property symbol, type

      def initialize(@symbol : Symbol, @type : TypeAnnotation)
      end
    end

    struct FFI
      property string, function

      def initialize(@string : NoonString, @function : Function)
      end
    end

    struct Call
      property name, args

      def initialize(@name : String, @args : Array(Expression))
      end
    end

    struct Condition
      property left, comparison, right

      def initialize(@left : Expression, @comparison : Comparison? = nil, @right : Expression? = nil)
      end
    end

    struct UInteger32
      property value

      def initialize(@value : UInt32)
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

    struct Comparison
      property comparison

      def initialize(@comparison : Token::Token)
      end
    end

    struct TypeAnnotation
      property type

      def initialize(@type : Type::Annotation)
      end
    end
  end
end
