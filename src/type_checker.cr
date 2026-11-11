module Noon
  module TypeChecker
    alias Expression = AST::Call | AST::UInteger32 | AST::NoonString | AST::Symbol

    struct Enviroment
      property env

      def initialize
        @env = Hash(String, Type::Type | Function).new
      end

      def push(key : String, type : Type::Type | Function)
        @env[key] = type
      end

      def get(key : String)
        Type::Type
        if @env.has_key?(key)
          @env[key]
        else
          abort("error: undefied #{key}")
        end
      end
    end

    struct Function
      property params, type

      def initialize(@params : Array(Type::Type), @type : Type::Type)
      end
    end

    def self.infer(expr : Expression, env : Enviroment)
      Type::Type
      case expr
      in AST::Call
        type = check_call(expr, env)
      in AST::UInteger32
        type = Type::Type::UInt32
      in AST::NoonString
        type = Type::Type::String
      in AST::Symbol
        type = env.get("symbol #{expr.name}")
      end

      if !type.is_a?(Function)
        type
      else
        abort("error: what?")
      end
    end

    def self.check_call(call : AST::Call, env : Enviroment)
      Type::Type
      function = env.get("function #{call.name}")
      if !function.is_a?(Function)
        abort("error: what?")
      end

      if call.args.size != function.params.size
        abort("error: too many arguments in call to #{call.name}")
      end

      i = 0
      call.args.each do |arg|
        inferred_type = infer(arg, env)
        if inferred_type != function.params[i]
          abort("error: expected #{function.params[i]} but found #{inferred_type}")
        end
        i += 1
      end

      function.type
    end

    def self.check_ffi(ffi : AST::FFI, env : Enviroment)
      env.push("function #{ffi.function.name}", check_function(ffi.function))
    end

    def self.check_function(function : AST::Function)
      Function
      env = Enviroment.new
      params = [] of Type::Type
      expected_type = function.type.type
      inferred_type : Type::Type = Type::Type::Nil

      function.params.each do |param|
        params.push(param.type.type)
        env.push("symbol #{param.symbol.name}", param.type.type)
      end

      function.body.each do |node|
        case node
        when AST::Function
          check_function(node)
        when AST::FFI
          check_ffi(node, env)
        when Expression
          inferred_type = infer(node, env)
        end
      end

      if inferred_type != expected_type
        abort("error: expected #{expected_type} but found #{inferred_type}")
      end

      Function.new(params, inferred_type)
    end

    def self.check(ast : Array(AST::Node))
      Type::Type
      env = Enviroment.new

      ast.each do |node|
        case node
        when AST::Function
          env.push("function #{node.name}", check_function(node))
        when AST::FFI
          check_ffi(node, env)
        when Expression
          infer(node, env)
        end
      end
    end
  end
end
