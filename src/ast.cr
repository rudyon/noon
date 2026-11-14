module Noon
  module AST
    alias Node = Expression | Value | ParseSymbolReturn | Keyword | PropertyParameter | ConditionComparison | TypeAnnotation | Conditional
    alias PropertyParameter = Property | Parameter
    alias ConditionComparison = Condition | Comparison
    alias Expression = ParseSymbolReturn | Value | Keyword
    alias Keyword = Type | Struct | Function | External | ExternalFunction
    alias Conditional = If | While
    alias ParseSymbolReturn = VariableTypeAnnotation | VariableDeclaration | VariableSetting | ConstantDeclaration | CallAccessSymbol
    alias CallAccessSymbol = Call | Access | Symbol
    alias Value = Number | NoonString | NoonBool

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

    struct NoonBool
      property value

      def initialize(@value : Bool)
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

      def initialize(@params : Array(Parameter), @type : TypeAnnotation)
      end
    end

    struct While
      property condition, body

      def initialize(@condition : Condition, @body : Array(Node))
      end
    end

    struct VariableTypeAnnotation
      property name, type

      def initialize(@name : String, @type : TypeAnnotation)
      end
    end

    struct VariableDeclaration
      property name, type, value

      def initialize(@name : String, @type : TypeAnnotation, @value : Value)
      end
    end

    struct VariableSetting
      property name, value

      def initialize(@name : String, @value : Value)
      end
    end

    struct ConstantDeclaration
      property name, type, value

      def initialize(@name : String, @type : TypeAnnotation, @value : Value)
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

    struct Number
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

      def initialize(@type : Noon::Type::Annotation, @extra : AST::Symbol? | Noon::Type::Annotation? = nil)
      end
    end
  end
end
