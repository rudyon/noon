module Noon
  module IR
    alias Operation = FunctionBegin | FunctionEnd | Parameter | FFI | Push | Return

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

    struct Push
      property value

      def initialize(@value : Int32)
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
        when .is_a?(AST::Function)
          nodes.concat(lower_function(node))
        when .is_a?(AST::Integer32)
          nodes.push(Push.new(node.value))
        end
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

    def self.lower_int32(int32 : AST::Integer32)
      Operation
      Push.new(int32.value)
    end

    def self.lower(ast : Array(AST::Node))
      Array(Operation)
      ir = [] of Operation

      ast.each do |node|
        case node
        when .is_a?(AST::Function)
          ir.concat(lower_function(node))
        when .is_a?(AST::FFI)
          ir.concat(lower_ffi(node))
        when .is_a?(AST::Integer32)
          ir.push(lower_int32(node))
        end
      end
      ir.push(Return.new)
    end

    def self.to_s(ir : Array(Operation))
      String
      s = ""

      ir.each do |op|
        case op
        when .is_a?(FunctionBegin)
          s += "FUNCTION_BEGIN #{op.name}\n"
        when .is_a?(FunctionEnd)
          s += "FUNCTION_END\n"
        when .is_a?(FFI)
          s += "FFI \"#{op.string}\"\n"
        when .is_a?(Push)
          s += "PUSH #{op.value}\n"
        when .is_a?(Return)
          s += "RETURN\n"
        end
      end

      s
    end
  end
end
