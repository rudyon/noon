module Noon
  module IR
    alias Operation = If | Then | FunctionBegin | FunctionEnd | Parameter | External | Call | Comparison | PushParam | PushSymbol | PushValue | PopReturn | Return
    alias Expression = PushSymbol | PushValue

    struct If
      def initialize
      end
    end

    struct Then
      def initialize
      end
    end

    struct FunctionBegin
      property name

      def initialize(@name : String)
      end
    end

    struct FunctionEnd
      def initialize
      end
    end

    struct Parameter
      property index

      def initialize(@index : Int32)
      end
    end

    struct External
      property string

      def initialize(@string : String)
      end
    end

    struct Call
      property name, params

      def initialize(@name : String, @params : Int32)
      end
    end

    struct Comparison
      property comparison

      def initialize(@comparison : Token::Token)
      end
    end

    struct PushParam
      property index

      def initialize(@index : Int32)
      end
    end

    struct PushSymbol
      property name

      def initialize(@name : String)
      end
    end

    struct PushValue
      property value

      def initialize(@value : UInt32 | String)
      end
    end

    struct PopReturn
      def initialize
      end
    end

    struct Return
      def initialize
      end
    end

    def self.lower_comp(comp : AST::Comparison)
      Operation
      Comparison.new(comp.comparison)
    end

    def self.lower_cond(cond : AST::Condition)
      Array(Operation)
      nodes = [] of Operation

      compare_from = cond.left
      case compare_from
      when AST::Call
        nodes.concat(lower_call(compare_from))
      when AST::UInteger32
        nodes.push(lower_uint32(compare_from))
      when AST::NoonString
        nodes.push(lower_string(compare_from))
      when AST::Symbol
        nodes.push(lower_symbol(compare_from))
      end

      comp = cond.comparison
      compare_to = cond.right
      if !comp.nil?
        nodes.push(lower_comp(comp))
        case compare_to
        when AST::Call
          nodes.concat(lower_call(compare_to))
        when AST::UInteger32
          nodes.push(lower_uint32(compare_to))
        when AST::NoonString
          nodes.push(lower_string(compare_to))
        when AST::Symbol
          nodes.push(lower_symbol(compare_to))
        end
      end

      nodes
    end

    def self.lower_if(if_node : AST::If)
      Array(Operation)
      nodes = [] of Operation

      nodes.push(If.new)

      nodes.concat(lower_cond(if_node.condition))

      if_node.body.each do |node|
        case node
        when AST::Function
          nodes.concat(lower_function(node))
        when AST::External
          nodes.concat(lower_ext(node))
        when AST::Call
          nodes.concat(lower_call(node))
        when AST::UInteger32
          nodes.push(lower_uint32(node))
        when AST::NoonString
          nodes.push(lower_string(node))
        when AST::Symbol
          nodes.push(lower_symbol(node))
        end
      end

      nodes.push(Then.new)
    end

    def self.lower_struct(strct : AST::Struct)
      Array(Operation)
      nodes = [] of Operation

      # TODO: implement struct lowering 
    end

    def self.lower_function(function : AST::Function)
      Array(Operation)
      nodes = [] of Operation
      nodes.push(FunctionBegin.new(function.name))

      i = 0
      function.params.each do |param|
        nodes.push(Parameter.new(i))
        i += 1
      end

      function.body.each do |node|
        case node
        when AST::Function
          nodes.concat(lower_function(node))
        when AST::External
          nodes.concat(lower_ext(node))
        when AST::Call
          nodes.concat(lower_call(node))
        when AST::UInteger32
          nodes.push(lower_uint32(node))
        when AST::NoonString
          nodes.push(lower_string(node))
        when AST::Symbol
          sbl = lower_symbol(node)

          i = 0
          function.params.each do |param|
            if sbl.is_a?(PushSymbol)
              if param.symbol == sbl.name
                sbl = PushParam.new(i)
              end
              i += 1
            else
              abort("error: what?")
            end
          end

          nodes.push(sbl)
        end
      end

      if nodes.last.is_a?(Expression)
        nodes.push(PopReturn.new)
      end

      nodes.push(FunctionEnd.new)

      nodes
    end

    def self.lower_ext(ext : AST::External)
      Array(Operation)
      nodes = [] of Operation
      nodes.push(External.new(ext.string.string))

      declare = ext.declaration
      case declare
      when AST::Function
        nodes.concat(lower_function(declare))
      when AST::Struct
        nodes.concat(lower_struct(declare))
      end

      nodes
    end

    def self.lower_call(call : AST::Call)
      Array(Operation)
      nodes = [] of Operation

      call.args.each do |arg|
        case arg
        in AST::If
          nodes.concat(lower_if(arg))
        in AST::Call
          nodes.concat(lower_call(arg))
        in AST::Condition
          nodes.concat(lower_cond(arg))
        in AST::UInteger32
          nodes.push(lower_uint32(arg))
        in AST::NoonString
          nodes.push(lower_string(arg))
        in AST::Symbol
          nodes.push(lower_symbol(arg))
        end
      end

      nodes.push(Call.new(call.name, call.args.size))
    end

    def self.lower_uint32(int32 : AST::UInteger32)
      Operation
      PushValue.new(int32.value)
    end

    def self.lower_string(string : AST::NoonString)
      Operation
      PushValue.new(string.string)
    end

    def self.lower_symbol(sbl : AST::Symbol)
      Operation
      PushSymbol.new(sbl.name)
    end

    def self.lower(ast : Array(AST::Node))
      Array(Operation)
      ir = [] of Operation

      ast.each do |node|
        case node
        when AST::Function
          ir.concat(lower_function(node))
        when AST::External
          ir.concat(lower_ext(node))
        when AST::Call
          ir.concat(lower_call(node))
        when AST::UInteger32
          ir.push(lower_uint32(node))
        when AST::NoonString
          ir.push(lower_string(node))
        when AST::Symbol
          ir.push(lower_symbol(node))
        end
      end

      if ir.last.is_a?(Expression)
        ir.push(PopReturn.new)
        ir.push(Return.new)
      elsif ir.last.is_a?(Call)
        ir.push(Return.new)
      end

      ir
    end

    def self.to_s(ir : Array(Operation))
      String
      s = ""

      ir.each do |op|
        case op
        in If
          s += "IF\n"
        in Then
          s += "THEN\n"
        in FunctionBegin
          s += "FUNCTION_BEGIN #{op.name}\n"
        in FunctionEnd
          s += "FUNCTION_END\n"
        in Parameter
          s += "PARAMETER #{op.index}\n"
        in External
          s += "EXTERNAL \"#{op.string}\"\n"
        in Call
          s += "CALL #{op.name} #{op.params}\n"
        in Comparison
          s += "#{op.comparison.lexeme}\n"
        in PushParam
          s += "PUSH_PARAMETER #{op.index}\n"
        in PushSymbol
          s += "PUSH #{op.name}\n"
        in PushValue
          case op.value
          in UInt32
            s += "PUSH #{op.value}\n"
          in String
            s += "PUSH \"#{op.value}\"\n"
          end
        in PopReturn
          s += "POP_RETURN\n"
        in Return
          s += "RETURN\n"
        end
      end

      s
    end
  end
end
