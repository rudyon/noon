module Noon
  module TypeChecker
    struct Enviroment
      property env

      def initialize
        @env = Hash(String, Type::Annotation | Function).new
      end

      def push(key : String, type : Type::Annotation | Function)
        @env[key] = type
      end

      def get(key : String)
        Type::Annotation
        if @env.has_key?(key)
          @env[key]
        else
          abort("error: undefined #{key}")
        end
      end
    end

    struct Struct
      property properties

      def initialize(@properties : Hash(String, Type::Annotation))
      end
    end

    struct Function
      property params, type

      def initialize(@params : Array(Type::Annotation), @type : Type::Annotation)
      end
    end

    def self.infer(expr : AST::Expression, env : Enviroment)
      AST::TypeAnnotation
      type = Type::Annotation::Nil
      extra = nil

      case expr
      in AST::If
        type = check_if(expr, env)
      in AST::Call
        type = check_call(expr, env)
      in AST::Access
        type = check_access(expr, env)
      in AST::Condition
        check_condition(expr, env)
        type = Type::Annotation::Bool
      in AST::Number
        type = Type::Annotation::UInt32
      in AST::NoonString
        type = Type::Annotation::Array
        extra = Type::Annotation::Char8
      in AST::NoonBool
        type = Type::Annotation::Bool
      in AST::Symbol
        type = env.get("symbol #{expr.name}")
      end

      if !type.is_a?(Type::Annotation)
        abort("#{expr}")
      end

      AST::TypeAnnotation.new(type, extra)
    end

    def self.check_body(parent : AST::Node)
      parent.body.each do |node|
        case node
        when AST::Function
          check_function(node)
        when AST::External
          check_ext(node, env)
        when AST::Expression
          infer(node, env)
        else
          abort("error: what?")
        end
      end
    end

    def self.check_if(if_node : AST::If, env : Enviroment)
      # TODO: implement type checking for ifs
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

    def self.check_condition(condition : AST::Condition, env : Enviroment)
      left = condition.left
      right = condition.right

      left_type = infer(left, env)
      if right
        right_type = infer(right, env)
      end

      if right_type
        if left_type != right_type
          abort("error: can't compare #{left_type} with #{right_type}")
        end
      elsif left_type != Bool
        abort("error: can't use #{left_type} in comparison")
      end
    end

    def self.check_access(access : AST::Access, env : Enviroment)
      # TODO: implement type checking for accesses
    end

    def self.check_ext(ext : AST::External, env : Enviroment)
      case ext
      when AST::Function
        env.push("function #{ext.declaration.name}", check_function(ext.declaration))
      when AST::Struct
        env.push("struct #{ext.declaration.name}", check_struct(ext.declaration))
      end
    end

    def self.check_function(function : AST::Function)
      Function
      env = Enviroment.new
      params = [] of Type::Annotation
      expected_type = function.type.type
      inferred_type = Type::Annotation::Nil

      function.params.each do |param|
        params.push(param.type.type)
        env.push("symbol #{param.symbol.name}", param.type.type)
      end

      if inferred_type != expected_type
        abort("error: expected #{expected_type} but found #{inferred_type}")
      end

      Function.new(params, inferred_type)
    end

    def self.check_struct(strct : AST::Struct)
      # TODO: implement type checking for structs
    end

    def self.check(ast : Array(AST::Node))
      Type::Type
      env = Enviroment.new

      ast.each do |node|
        case node
        when AST::Function
          env.push("function #{node.name}", check_function(node))
        when AST::External
          check_ext(node, env)
        when AST::Expression
          infer(node, env)
        end
      end
    end
  end
end
