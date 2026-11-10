module Noon
  module TypeChecker
    alias Expression = AST::UInteger32 | AST::NoonString | AST::Symbol

    struct Enviroment
      property env

      def initialize
        @env = Hash(String, Type::Type).new
      end

      def push(key : String, type : Type::Type)
        @env[key] = type
      end

      def get(key : String)
        Type::Type
        @env[key]
      end
    end

    def self.infer(expr : Expression, env : Enviroment)
      Type::Type
      case expr
      in AST::UInteger32
        Type::Type::UInt32
      in AST::NoonString
        Type::Type::String
      in AST::Symbol
        env.get(expr.name)
      end
    end

    def self.check_call(call : AST::Call, env : Enviroment)
      Type::Type
      env.get(call.name)
    end

    def self.check_ffi(ffi : AST::FFI)
      Type::Type
      check_function(ffi.function)
    end

    def self.check_function(function : AST::Function)
      Type::Type
      env = Enviroment.new
      expected_type = function.type.type
      inferred_type = Type::Type::Nil

      function.params.each do |param|
        env.push(param.symbol.name, param.type.type)
      end

      function.body.each do |node|
        case node
        when AST::Function
          check_function(node)
        when AST::FFI
        when AST::Call
        when AST::UInteger32
          inferred_type = infer(node, env)
        when AST::NoonString
          inferred_type = infer(node, env)
        when AST::Symbol
          inferred_type = infer(node, env)
        end
      end

      if inferred_type != expected_type
        abort("error: expected #{expected_type} but found #{inferred_type}")
      end

      inferred_type
    end

    def self.check(ast : Array(AST::Node))
      Type::Type
      env = Enviroment.new

      ast.each do |node|
        case node
        when AST::Function
          env.push(node.name, check_function(node))
        when AST::FFI
          check_ffi(node)
        when AST::Call
          check_call(node, env)
        when Expression
          infer(node, env)
        end
      end

      Type::Type::Nil
    end
  end
end
