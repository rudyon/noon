module Noon
  module AST
    alias Node = If | Type | Function | Parameter | External | Call | Access | UInteger32 | NoonString | Symbol | TypeAnnotation
    alias Expression = Call | Access | UInteger32 | NoonString | Symbol

    struct If
      property condition, body

      def initialize(@condition : Condition, @body : Array(Node))
      end
    end

    struct Type
      property symbol, type

      def initialize(@symbol : Symbol, @type : TypeAnnotation | External)
      end
    end

    struct Struct
      property symbol, properties

      def initialize(@symbol : Symbol, @properties : Array(Property))
      end
    end

    struct Property
      property symbol, type

      def initialize(@symbol : Symbol, @type : TypeAnnotation)
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

    struct External
      property string, declaration

      def initialize(@string : NoonString, @declaration : Function | Struct | ExternalFunction)
      end
    end

    struct ExternalFunction
      property params, type

      def initialize(@params : Array(Parameter), @tpe : TypeAnnotation)
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

    struct Access
      property accessed, accessor

      def initialize(@accessed : Symbol, @accessor : Array(Symbol | Call))
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
      property type, extra

      def initialize(@type : Noon::Type::Annotation, @extra : AST::Symbol? = nil)
      end
    end
  end
end
