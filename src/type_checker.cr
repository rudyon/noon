module Noon
  module TypeChecker
    struct Enviroment
      property env

      def initialize
        @env = Hash(String, Type::Annotation | Function | Struct).new
      end

      def push(key : String, type : Type::Annotation | Function | Struct)
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

      def initialize(@properties : Hash(String, AST::TypeAnnotation))
      end
    end

    struct Function
      property params, type

      def initialize(@params : Array(Type::Annotation), @type : Type::Annotation)
      end
    end

    def self.infer(expr : AST::Expression, env : Enviroment)
      AST::TypeAnnotation
      t = Type::Annotation::Nil
      extra = nil

      case expr
      in AST::Function
        t = check_function(expr, env).type
      in AST::External
        t = check_ext(expr, env)
      in AST::ExternalFunction
        t = expr.type.type
      in AST::Struct
        abort("error: structs must be defined at the top level")
      in AST::Type
        abort("error: types must be defined at the top level")
      in AST::Call
        t = check_call(expr, env)
      in AST::Access
        t = check_access(expr, env)
      in AST::Condition
        check_condition(expr, env)
        t = Type::Annotation::Bool
      in AST::Number
        t = Type::Annotation::UInt32
      in AST::NoonString
        t = Type::Annotation::Array
        extra = Type::Annotation::Char8
      in AST::NoonBool
        t = Type::Annotation::Bool
      in AST::Symbol
        t = env.get("symbol #{expr.name}")
      in AST::ConstantDeclaration
        t = expr.type.type
        env.push("symbol #{expr.name}", t)

        t
      in AST::VariableDeclaration
        t = expr.type.type
        env.push("symbol #{expr.name}", t)

        t
      in AST::VariableSetting
        t = env.get("symbol #{expr.name}")
        v = expr.value

        if t.is_a?(Type::Annotation)
          if v.is_a?(AST::NoonString)
            if t != Type::Annotation::Char8 && t != Type::Annotation::Char16
              abort("error: #{v} cannot be converted to #{t} implicitly")
            end
          elsif v.is_a?(AST::Number)
            if t != Type::Annotation::UInt32 | t != Type::Annotation::UInt64 | t != Type::Annotation::Int32 | t != Type::Annotation::Int64
              abort("error: #{v} cannot be converted to #{t} implicitly")
            else
              case t
              when Type::Annotation::UInt32
                if v.value < 0u32 || v.value > 4294967295u32
                  abort("error: #{v} cannot be converted to #{t} implicitly")
                end
              when Type::Annotation::UInt64
                if v.value < 0u64 || v.value > 18446744073709551615u64
                  abort("error: #{v} cannot be converted to #{t} implicitly")
                end
              when Type::Annotation::Int32
                if v.value < -2147483648i32 || v.value > 2147483647i32
                  abort("error: #{v} cannot be converted to #{t} implicitly")
                end
              when Type::Annotation::Int64
                if v.value < -9223372036854775808i64 || v.value > 9223372036854775808u64
                  abort("error: #{v} cannot be converted to #{t} implicitly")
                end
              else
                abort("error: #{v} cannot be converted to #{t} implicitly")
              end
            end
          elsif v.is_a?(AST::NoonBool)
            if t != Type::Annotation::Bool
              abort("error: #{v} cannot be converted to #{t} implicitly")
            end
          end
        else
          abort("error: #{v} cannot be converted to #{t} implicitly")
        end
      in AST::VariableTypeAnnotation
        t = expr.type.type
        env.push("symbol #{expr.name}", t)

        t
      end

      if !t.is_a?(Type::Annotation)
        abort("#{expr} check returns wrong thing")
      end

      AST::TypeAnnotation.new(t, extra)
    end

    def self.check_while(while_node : AST::While, env : Enviroment)
      Type::Annotation
      check_condition(while_node.condition, env)
      type = check_body(while_node, env)
      if type.nil?
        AST::TypeAnnotation.new(Type::Annotation::Never)
      else
        type
      end
    end

    def self.check_body(parent : AST::Node, env : Enviroment)
      AST::TypeAnnotation
      type = AST::TypeAnnotation.new(Type::Annotation::Nil)
      parent.body.each do |node|
        case node
        when AST::Expression
          type = infer(node, env)
        when AST::While
          type = check_while(node, env)
        when AST::If
          type = check_if(node, env)
        else
          abort("error: what? 1 #{node}")
        end
      end

      type
    end

    def self.check_if(if_node : AST::If, env : Enviroment)
      AST::TypeAnnotation
      check_condition(if_node.condition, env)
      check_body(if_node, env)
    end

    def self.check_call(call : AST::Call, env : Enviroment)
      Type::Annotation
      function = env.get("function #{call.name}")
      if !function.is_a?(Function)
        abort("error: what? 2")
      end

      if call.args.size != function.params.size
        abort("error: too many arguments in call to #{call.name}")
      end

      i = 0
      call.args.each do |arg|
        inferred_type = infer(arg, env).type
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
        if left_type.type != right_type.type
          abort("error: can't compare #{left_type} with #{right_type}")
        end
      elsif left_type.type != Type::Annotation::Bool
        abort("error: can't use #{left_type} in comparison")
      end
    end

    def self.check_access(access : AST::Access, env : Enviroment)
      # TODO: implement type checking for accesses
    end

    def self.check_ext(ext : AST::External, env : Enviroment)
      d = ext.declaration
      case d
      when AST::ExternalFunction
        check_ext_fnc(d, env)
      when AST::Struct
        env.push("struct #{d.symbol.name}", check_struct(d))
      when AST::Function
        env.push("function #{d.name}", check_function(d, env))
      else
        abort("type checking for #{d} nees to be implemented")
      end
    end

    def self.check_ext_fnc(func : AST::ExternalFunction, outer_env : Enviroment)
      Function
      env = Enviroment.new
      params = [] of Type::Annotation
      t = func.type.type
      t_extra = func.type.extra

      func.params.each do |param|
        params.push(param.type.type)
        env.push("symbol #{param.symbol.name}", param.type.type)
      end

      Function.new(params, t)
    end

    def self.check_function(function : AST::Function, outer_env : Enviroment)
      Function
      env = Enviroment.new
      params = [] of Type::Annotation
      expected_type = function.type.type
      type_extra = function.type.extra
      inferred_type = Type::Annotation::Nil

      function.params.each do |param|
        params.push(param.type.type)
        env.push("symbol #{param.symbol.name}", param.type.type)
      end

      inferred_type = check_body(function, env).type

      if inferred_type.nil?
        abort("expected #{function.type.type} not #{inferred_type}")
      end

      if expected_type == Type::Annotation::Derived && type_extra.is_a?(AST::Symbol)
        if inferred_type != outer_env.get("symbol #{type_extra.name}")
          abort("error: expected #{type_extra.name} but found #{inferred_type} 1")
        else
          Function.new(params, inferred_type)
        end
      elsif expected_type == Type::Annotation::Never
        Function.new(params, expected_type)
      elsif inferred_type != expected_type
        abort("error: expected #{expected_type} but found #{inferred_type} 2")
      else
        Function.new(params, inferred_type)
      end
    end

    def self.check_struct(strct : AST::Struct)
      Struct
      props = Hash(String, AST::TypeAnnotation).new

      strct.properties.each do |prop|
        props[prop.symbol.name] = prop.type
      end

      Struct.new(props)
    end

    def self.check_type(type : AST::Type, env : Enviroment)
      t = type.type
      case t
      when AST::TypeAnnotation
        env.push("symbol #{type.symbol.name}", t.type)
      when AST::External
        env.push("function #{type.symbol.name}", check_ext(t, env))
      end
    end

    def self.check(ast : Array(AST::Node))
      Type::Type
      env = Enviroment.new

      ast.each do |node|
        case node
        when AST::External
          check_ext(node, env)
        when AST::Struct
          env.push("struct #{node.symbol.name}", check_struct(node))
        when AST::Type
          check_type(node, env)
        when AST::Expression
          infer(node, env)
        end
      end
    end
  end
end
