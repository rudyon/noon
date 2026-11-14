module Noon
  module Parser
    struct Reader
      property tokens, pos

      def initialize(@tokens : Array(Token::Token))
        @pos = 0
      end

      def peek
        Token::Token
        @tokens[@pos]
      end

      def advance
        @pos += 1
      end

      def consume
        Token::Token
        t = peek()
        advance()
        t
      end

      def eof?
        @pos >= @tokens.size
      end
    end

    def self.parse_typeannotation(reader : Reader)
      {AST::TypeAnnotation, Reader}
      extra = nil

      token = reader.consume
      case token.kind
      when Token::Kind::Symbol
        case token.lexeme
        when "Void"
          type = Type::Annotation::Void
        when "Bool"
          type = Type::Annotation::Bool
        when "UInt32"
          type = Type::Annotation::UInt32
        when "UInt64"
          type = Type::Annotation::UInt64
        when "Int32"
          type = Type::Annotation::Int32
        when "Int64"
          type = Type::Annotation::Int64
        when "Char8"
          type = Type::Annotation::Char8
        when "Char16"
          type = Type::Annotation::Char16
        else
          type = Type::Annotation::Derived
          sbl, reader = parse_symbol(reader, token)
          if sbl.is_a?(AST::Symbol)
            extra = sbl
          end
        end
      when Token::Kind::ArrayEmpty
        type = Type::Annotation::Array
        token = reader.consume
        sbl, reader = parse_symbol(reader, token)
        if sbl.is_a?(AST::Symbol)
          extra = sbl
        end
      when Token::Kind::Asterisk
        type = Type::Annotation::Pointer
        token = reader.consume
        sbl, reader = parse_symbol(reader, token)
        if sbl.is_a?(AST::Symbol)
          extra = sbl
        end
      when Token::Kind::Bang
        type = Type::Annotation::Never
      else
        abort("error: unexpected type annotation #{token.lexeme}")
      end

      {AST::TypeAnnotation.new(type, extra), reader}
    end

    def self.parse_expression(reader : Reader, token : Token::Token)
      {AST::Expression, Reader}

      case token.kind
      when Token::Kind::String
        {AST::NoonString.new(token.lexeme), reader}
      when Token::Kind::Symbol
        node, reader = parse_symbol(reader, token)
        {node, reader}
      when Token::Kind::Number
        node = parse_number(token)
        {node, reader}
      when Token::Kind::True
        node = AST::NoonBool.new(true)
        {node, reader}
      when Token::Kind::False
        node = AST::NoonBool.new(false)
        {node, reader}
      else
        abort("unexpected expression #{token}")
      end
    end

    def self.parse_symbol(reader : Reader, token : Token::Token)
      {AST::ParseSymbolReturn, Reader}

      if reader.peek.kind == Token::Kind::ParenOpen
        args = [] of AST::Expression

        while reader.peek.kind != Token::Kind::ParenClose
          consumed = reader.consume
          case consumed.kind
          when .expression?
            node, reader = parse_expression(reader, consumed)
            if node.is_a?(AST::Expression)
              args.push(node)
            else
              abort("error: what1?")
            end
          when Token::Kind::Comma
            consumed = reader.consume
            sbl, reader = parse_symbol(reader, consumed)
            if sbl.is_a?(AST::Expression)
              args.push(sbl)
            else
              abort("error: expected expression but found #{sbl}")
            end
          else
            reader.consume
          end
        end
        reader.consume

        {AST::Call.new(token.lexeme, args), reader}
      elsif reader.peek.kind == Token::Kind::Period
        accessed = AST::Symbol.new(token.lexeme)
        accesses = [] of AST::Symbol | AST::Call

        while reader.peek.kind == Token::Kind::Period
          reader.consume
          consumed = reader.consume

          if consumed.kind == Token::Kind::Symbol && reader.peek.kind != Token::Kind::ParenOpen
            accesses.push(AST::Symbol.new(consumed.lexeme))
          else
            call, reader = parse_symbol(reader, consumed)

            if call.is_a?(AST::Call)
              accesses.push(call)
            else
              abort("error: what2?")
            end
          end
        end

        {AST::Access.new(accessed, accesses), reader}
      else
        if reader.peek.kind == Token::Kind::Symbol
          name = token.lexeme

          type, reader = parse_typeannotation(reader)

          if reader.peek.kind == Token::Kind::Equals
            reader.consume

            consumed = reader.consume
            value, reader = parse_expression(reader, consumed)
            if value.is_a?(AST::Value)
              {AST::VariableDeclaration.new(name, type, value), reader}
            else
              abort("error: what3?")
            end
          else
            {AST::VariableTypeAnnotation.new(name, type), reader}
          end
        elsif reader.peek.kind == Token::Kind::Equals
          name = token.lexeme

          reader.consume
          consumed = reader.consume

          value, reader = parse_expression(reader, consumed)

          if value.is_a?(AST::Value)
            {AST::VariableSetting.new(name, value), reader}
          else
            {AST::Symbol.new(name), reader}
          end
        elsif reader.peek.kind == Token::Kind::Constant
          reader.consume

          if reader.peek.kind == Token::Kind::Symbol
            name = reader.consume.lexeme
            consumed = reader.consume

            type_sbl, reader = parse_symbol(reader, consumed)
            type, reader = parse_typeannotation(reader)

            if reader.peek.kind == Token::Kind::Equals
              reader.consume
              consumed = reader.consume

              value, reader = parse_expression(reader, consumed)

              if value.is_a?(AST::Value)
                {AST::ConstantDeclaration.new(name, type, value), reader}
              else
                abort("error: what5?")
              end
            else
              abort("error: expected equals but found #{reader.consume.lexeme}")
            end
          else
            abort("error: expected constant name but found #{reader.consume.lexeme}")
          end
        else
          {AST::Symbol.new(token.lexeme), reader}
        end
      end
    end

    def self.parse_number(token : Token::Token)
      AST::Number
      AST::Number.new(token.lexeme.to_u32)
    end

    def self.parse_ext_function(reader : Reader)
      {AST::ExternalFunction, Reader}
      params = [] of AST::Parameter
      type = AST::TypeAnnotation.new(Type::Annotation::Nil)

      while reader.peek.kind != Token::Kind::ParenClose
        consumed = reader.consume
        case consumed.kind
        when Token::Kind::ParenOpen
          params, reader = parse_function_params(reader)
        when Token::Kind::RArrow
          type, reader = parse_typeannotation(reader)
        when .whitespace?
          next
        else
          abort("error: expected ParenOpen or RightArrow but got #{consumed}")
        end
      end
      reader.consume

      {AST::ExternalFunction.new(params, type), reader}
    end

    def self.parse_ext(reader : Reader)
      {AST::External, Reader}
      if reader.peek.kind == Token::Kind::String
        consumed = reader.consume
        string, reader = parse_expression(reader, consumed)
        if !string.is_a?(AST::NoonString)
          abort("error: expected string after ext")
        end
      else
        abort("error: expected #{Token::Kind::String} but found #{reader.peek}")
      end

      consumed = reader.consume
      case consumed.kind
      when Token::Kind::Function
        if reader.peek.kind == Token::Kind::Symbol
          declare, reader = parse_function(reader)
        elsif reader.peek.kind == Token::Kind::ParenOpen
          declare, reader = parse_ext_function(reader)
        else
          abort("error: expected some kind of function declaration")
        end
      when Token::Kind::Struct
        declare, reader = parse_struct(reader)
      else
        abort("error: expected #{Token::Kind::Function} or #{Token::Kind::Struct} but found #{consumed.kind}")
      end

      {AST::External.new(string, declare), reader}
    end

    def self.parse_body(reader : Reader)
      {Array(AST::Node), Reader}
      body = [] of AST::Node

      while reader.peek.kind != Token::Kind::CurlyClose
        consumed = reader.consume
        case consumed.kind
        when Token::Kind::EOF
          abort("error: expected #{Token::Kind::CurlyClose} but found #{consumed}")
        when .expression?
          expr, reader = parse_expression(reader, consumed)
          body.push(expr)
        when Token::Kind::If
          if_node, reader = parse_if(reader)
          body.push(if_node)
        when Token::Kind::While
          while_node, reader = parse_while(reader)
          body.push(while_node)
        when Token::Kind::Symbol
          sbl, reader = parse_symbol(reader, consumed)
          case sbl
          when AST::ParseSymbolReturn
            body.push(sbl)
          end
        end
      end
      reader.consume

      {body, reader}
    end

    def self.parse_function_params(reader : Reader)
      {Array(AST::Parameter), Reader}
      params = [] of AST::Parameter

      while reader.peek.kind != Token::Kind::ParenClose
        consumed = reader.consume
        case consumed.kind
        when Token::Kind::Symbol
          param_sbl, reader = parse_symbol(reader, consumed)

          if param_sbl.is_a?(AST::Symbol)
            consumed = reader.consume
            if consumed.kind != Token::Kind::Colon
              abort("error: expected #{Token::Kind::Colon} but found #{consumed.kind}")
            else
              param_type, reader = parse_typeannotation(reader)
            end

            if reader.peek.kind == Token::Kind::Comma
              reader.consume
              params.push(AST::Parameter.new(param_sbl, param_type))
            else
              params.push(AST::Parameter.new(param_sbl, param_type))
              break
            end
          else
            abort("error: unexpected function param 1 #{param_sbl}")
          end
        when .whitespace?
          next
        else
          abort("error: unexpected function param 2 #{consumed.kind}")
        end
      end
      reader.consume

      {params, reader}
    end

    def self.parse_function(reader : Reader)
      {AST::Function, Reader}
      params = [] of AST::Parameter

      if reader.peek.kind == Token::Kind::Symbol
        name = reader.consume.lexeme
      else
        abort("error: expected #{Token::Kind::Symbol} but found #{reader.peek}")
      end

      if reader.peek.kind == Token::Kind::ParenOpen
        reader.consume
        params, reader = parse_function_params(reader)
      end

      if reader.peek.kind == Token::Kind::RArrow
        reader.consume
        type, reader = parse_typeannotation(reader)
      else
        abort("error: expected #{Token::Kind::RArrow} but found #{reader.peek.kind}")
      end

      if reader.peek.kind == Token::Kind::CurlyOpen
        reader.consume
        body, reader = parse_body(reader)
      else
        abort("error: expected #{Token::Kind::CurlyOpen} but found #{reader.peek.kind}")
      end

      {AST::Function.new(name, params, type, body), reader}
    end

    def self.parse_struct(reader : Reader)
      {AST::Struct, Reader}
      properties = [] of AST::Property

      if reader.peek.kind == Token::Kind::Symbol
        consumed = reader.consume
        sbl, reader = parse_symbol(reader, consumed)

        if !sbl.is_a?(AST::Symbol)
          abort("error: what6?")
        end
      else
        abort("error: expected symbol after struct")
      end

      if reader.peek.kind == Token::Kind::CurlyOpen
        reader.consume

        while reader.peek.kind != Token::Kind::CurlyClose
          consumed = reader.consume
          case consumed.kind
          when Token::Kind::Symbol
            prop_sbl, reader = parse_symbol(reader, consumed)

            if prop_sbl.is_a?(AST::Symbol)
              consumed = reader.consume
              if consumed.kind == Token::Kind::Colon
                prop_type, reader = parse_typeannotation(reader)

                if reader.peek.kind == Token::Kind::Comma
                  reader.consume
                  properties.push(AST::Property.new(prop_sbl, prop_type))
                else
                  properties.push(AST::Property.new(prop_sbl, prop_type))
                end
              end
            else
              abort("error: expected symbol but found #{prop_sbl}")
            end
          when .whitespace?
            next
          else
            abort("error: unexpected struct #{consumed}")
          end
        end

        reader.consume
      else
        abort("error: expected #{Token::Kind::CurlyOpen} but found #{reader.peek}")
      end

      {AST::Struct.new(sbl, properties), reader}
    end

    def self.parse_type(reader : Reader)
      {AST::Type, Reader}

      if reader.peek.kind == Token::Kind::Symbol
        name = reader.consume
        name = AST::Symbol.new(name.lexeme)

        if !name.is_a?(AST::Symbol)
          abort("error: what7?")
        end
      else
        abort("error: expected symbol after type")
      end

      if reader.peek.kind == Token::Kind::Equals
        reader.consume
      else
        abort("error: expected an equals in type declaration")
      end

      if reader.peek.kind == Token::Kind::External
        reader.consume
        ext, reader = parse_ext(reader)

        {AST::Type.new(name, ext), reader}
      elsif reader.peek.kind == Token::Kind::Symbol
        type, reader = parse_typeannotation(reader)

        {AST::Type.new(name, type), reader}
      else
        abort("error: expected symbol after equals in type declaration")
      end
    end

    def self.parse_conditional(reader : Reader)
      {AST::Condition, Array(AST::Node), Reader}

      if reader.peek.kind.expression?
        consumed = reader.consume
        left, reader = parse_expression(reader, consumed)

        if !left.is_a?(AST::Expression)
          abort("error: what8?")
        end
      else
        abort("error: expected a condition after while")
      end

      if reader.peek.kind.comparison?
        comparison = reader.consume
      end

      if comparison
        if reader.peek.kind.expression?
          consumed = reader.consume
          right, reader = parse_expression(reader, consumed)
          if !right.is_a?(AST::Expression)
            abort("error: what9?")
          end
        else
          abort("error: expected an expression after #{comparison} but found #{consumed}")
        end

        condition = AST::Condition.new(left, AST::Comparison.new(comparison), right)
      else
        condition = AST::Condition.new(left)
      end

      if reader.peek.kind == Token::Kind::CurlyOpen
        reader.consume
        body, reader = parse_body(reader)
      else
        abort("error: expected #{Token::Kind::CurlyOpen} but found #{reader.peek}")
      end

      {condition, body, reader}
    end

    def self.parse_if(reader : Reader)
      {AST::If, Reader}

      condition, body, reader = parse_conditional(reader)

      {AST::If.new(condition, body), reader}
    end

    def self.parse_while(reader : Reader)
      {AST::While, Reader}

      condition, body, reader = parse_conditional(reader)

      {AST::While.new(condition, body), reader}
    end

    def self.parse(tokens : Array(Token::Token))
      Array(AST::Node)
      ast = [] of AST::Node
      reader = Reader.new(tokens)

      while !reader.eof?
        consumed = reader.consume
        case consumed.kind
        when Token::Kind::If
          node, reader = parse_if(reader)
          ast.push(node)
        when Token::Kind::Type
          node, reader = parse_type(reader)
          ast.push(node)
        when Token::Kind::Function
          node, reader = parse_function(reader)
          ast.push(node)
        when Token::Kind::External
          node, reader = parse_ext(reader)
          ast.push(node)
        when Token::Kind::While
          node, reader = parse_while(reader)
          ast.push(node)
        when .expression?
          node, reader = parse_expression(reader, consumed)
          ast.push(node)
        end
      end

      ast
    end
  end
end
