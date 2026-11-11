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

      consumed = reader.consume
      if consumed.kind == Token::Kind::Symbol
        case consumed.lexeme
        when "Bool"
          type = Type::Annotation::Bool
        when "UInt"
          case reader.consume.lexeme
          when "32"
            type = Type::Annotation::UInt32
          else
            abort("error: no typed named UInt did you mean UInt32?")
          end
        else
          abort("error: #{consumed.lexeme} is not a valid type")
        end
      else
        abort("error: unexpected #{consumed}")
      end

      {AST::TypeAnnotation.new(type), reader}
    end

    def self.parse_expression(reader : Reader, token : Token::Token)
      {AST::Expression, Reader}

      case token
      when Token::Kind::DoubleQuote
        node, reader = parse_string(reader)
        {node, reader}
      when Token::Kind::Symbol
        node, reader = parse_symbol(reader, token)
        {node, reader}
      when Token::Kind::Number
        node = parse_number(token)
        {node, reader}
      else
        abort("unexpected #{token}")
      end
    end

    def self.parse_symbol(reader : Reader, token : Token::Token)
      {AST::Symbol | AST::Call, Reader}

      if reader.peek.kind == Token::Kind::ParenOpen
        reader.consume
        args = [] of AST::Expression

        while reader.peek.kind != Token::Kind::ParenClose
          consumed = reader.consume
          case consumed.kind
          when Token::Kind::DoubleQuote
            s, reader = parse_string(reader)
            args.push(s)
          when Token::Kind::Number
            args.push(parse_number(consumed))
          when Token::Kind::Symbol
            sbl, reader = parse_symbol(reader, consumed)
            args.push(sbl)
          else
            abort("error: unexpected #{consumed}")
          end
        end
        reader.consume

        {AST::Call.new(token.lexeme, args), reader}
      else
        {AST::Symbol.new(token.lexeme), reader}
      end
    end

    def self.parse_number(token : Token::Token)
      AST::UInteger32
      AST::UInteger32.new(token.lexeme.to_u32)
    end

    def self.parse_string(reader : Reader)
      {AST::NoonString, Reader}
      s = [] of String

      while reader.peek.kind != Token::Kind::DoubleQuote
        consumed = reader.consume
        case consumed.kind
        when Token::Kind::EOF
          abort("error: expected #{Token::Kind::DoubleQuote} but found #{consumed}")
        when Token::Kind::Symbol
          sbl, reader = parse_symbol(reader, consumed)
          case sbl
          when AST::Symbol
            s.push(sbl.name)
          when AST::Call
            s.push(sbl.name) # TODO: fix this
          end
        when Token::Kind::Number
          s.push(parse_number(consumed).to_s)
        end
      end
      reader.consume

      string = AST::NoonString.new(s.join(" ")) # TODO: this turns all whitespace into a single space. it shouldn't do that
      {string, reader}
    end

    def self.parse_ffi(reader : Reader)
      {AST::FFI, Reader}
      if reader.peek.kind == Token::Kind::DoubleQuote
        reader.consume
        string, reader = parse_string(reader)
      else
        abort("error: expected #{Token::Kind::DoubleQuote} but found #{reader.peek}")
      end

      if reader.peek.kind == Token::Kind::Function
        reader.consume
        function, reader = parse_function(reader)
      else
        abort("error: expected #{Token::Kind::Function} but found #{reader.peek}")
      end

      {AST::FFI.new(string, function), reader}
    end

    def self.parse_body(reader : Reader)
      {Array(AST::Node), Reader}
      body = [] of AST::Node

      while reader.peek.kind != Token::Kind::CurlyClose
        consumed = reader.consume
        case consumed.kind
        when Token::Kind::EOF
          abort("error: expected #{Token::Kind::CurlyClose} but found #{consumed}")
        when Token::Kind::Number
          body.push(parse_number(consumed))
        when Token::Kind::Symbol
          sbl, reader = (parse_symbol(reader, consumed))
          case sbl
          when AST::Symbol
            body.push(sbl)
          when AST::Call
            abort("error: function calls inside bodies are not supported yet") # TODO
          end
        end
      end
      reader.consume

      {body, reader}
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

        while reader.peek.kind != Token::Kind::ParenClose
          consumed = reader.consume
          case consumed.kind
          when Token::Kind::Symbol
            param_sbl, reader = parse_symbol(reader, consumed)

            if param_sbl.is_a?(AST::Symbol)
              consumed = reader.consume
              if consumed.kind != Token::Kind::Colon
                abort("error: expected #{Token::Kind::Colon} but found #{consumed}")
              else
                param_type, reader = parse_typeannotation(reader)
              end

              params.push(AST::Parameter.new(param_sbl, param_type))
            else
              abort("error: unexpected #{param_sbl}")
            end
          else
            abort("error: unexpected #{consumed}")
          end
        end
        reader.consume
      end

      if reader.peek.kind == Token::Kind::RArrow
        reader.consume
        type, reader = parse_typeannotation(reader)
      else
        abort("error: expected #{Token::Kind::RArrow} but found #{reader.peek}")
      end

      if reader.peek.kind == Token::Kind::CurlyOpen
        reader.consume
        body, reader = parse_body(reader)
      else
        abort("error: expected #{Token::Kind::CurlyOpen} but found #{reader.peek}")
      end

      {AST::Function.new(name, params, type, body), reader}
    end

    def self.parse_if(reader : Reader)
      {AST::If, Reader}

      if reader.peek.kind.expression?
        consumed = reader.consume
        left, reader = parse_expression(reader, consumed)
      else
        abort("error: expected a condition after if")
      end

      if reader.peek.kind.comparison?
        comparison = reader.consume
      end

      if comparison
        if reader.peek.kind.expression?
          consumed = reader.consume
          right, reader = parse_expression(reader, consumed)
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

      {AST::If.new(condition, body), reader}
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
        when Token::Kind::Function
          node, reader = parse_function(reader)
          ast.push(node)
        when Token::Kind::FFI
          node, reader = parse_ffi(reader)
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
