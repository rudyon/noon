module Noon
  module IR
    alias Operation = FunctionBegin | FunctionEnd | Parameter | FFI | Call | PushParam | PushSymbol | PushValue | PopReturn | Return
    alias Expression = Call | PushSymbol | PushValue

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

    struct FFI
      property string

      def initialize(@string : String)
      end
    end

    struct Call
      property name, params

      def initialize(@name : String, @params : Int32)
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

      def initialize(@value : Int32 | String)
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
        in AST::Function
          nodes.concat(lower_function(node))
        in AST::FFI
          nodes.concat(lower_ffi(node))
        in AST::Call
          nodes.concat(lower_call(node))
        in AST::Integer32
          nodes.push(lower_int32(node))
        in AST::NoonString
          nodes.push(lower_string(node))
        in AST::Symbol
          sbl = lower_symbol(node)

          i = 0
          function.params.each do |param|
            if sbl.is_a?(PushSymbol)
              if param.name == sbl.name
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

    def self.lower_ffi(ffi : AST::FFI)
      Array(Operation)
      nodes = [] of Operation
      nodes.push(FFI.new(ffi.string.string))
      nodes.concat(lower_function(ffi.function))

      nodes
    end

    def self.lower_call(call : AST::Call)
      Array(Operation)
      nodes = [] of Operation

      call.args.each do |arg|
        case arg
        in AST::Call
          nodes.concat(lower_call(arg))
        in AST::Integer32
          nodes.push(lower_int32(arg))
        in AST::NoonString
          nodes.push(lower_string(arg))
        in AST::Symbol
          nodes.push(lower_symbol(arg))
        end
      end

      nodes.push(Call.new(call.name, call.args.size))
    end

    def self.lower_int32(int32 : AST::Integer32)
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
        in AST::Function
          ir.concat(lower_function(node))
        in AST::FFI
          ir.concat(lower_ffi(node))
        in AST::Call
          ir.concat(lower_call(node))
        in AST::Integer32
          ir.push(lower_int32(node))
        in AST::NoonString
          ir.push(lower_string(node))
        in AST::Symbol
          ir.push(lower_symbol(node))
        end
      end

      if ir.last.is_a?(Expression)
        ir.push(PopReturn.new)
        ir.push(Return.new)
      end

      ir
    end

    def self.to_s(ir : Array(Operation))
      String
      s = ""

      ir.each do |op|
        case op
        in FunctionBegin
          s += "FUNCTION_BEGIN #{op.name}\n"
        in FunctionEnd
          s += "FUNCTION_END\n"
        in Parameter
          s += "PARAMETER #{op.index}\n"
        in FFI
          s += "FFI \"#{op.string}\"\n"
        in Call
          s += "CALL #{op.name} #{op.params}\n"
        in PushParam
          s += "PUSH_PARAMETER #{op.index}\n"
        in PushSymbol
          s += "PUSH #{op.name}\n"
        in PushValue
          case op.value
          in Int32
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
