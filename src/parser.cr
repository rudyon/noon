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

    def self.parse_symbol(token : Token::Token)
      String
      token.lexeme
    end

    def self.parse_number(token : Token::Token)
      AST::Integer32
      AST::Integer32.new(token.lexeme.to_i)
    end

    def self.parse_string(reader : Reader)
      {AST::NoonString, Reader}
      s = [] of String

      while reader.peek.kind != Token::Kind::DoubleQuote
        consumed = reader.consume
        case consumed.kind
        when Token::Kind::EOF
          abort("error: expected #{Token::Kind::DoubleQuote} but found #{consumed.kind}")
        when Token::Kind::Symbol
          s.push(parse_symbol(consumed))
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
        abort("error: expected #{Token::Kind::DoubleQuote} but found #{reader.peek.kind}")
      end

      if reader.peek.kind == Token::Kind::Function
        reader.consume
        function, reader = parse_function(reader)
      else
        abort("error: expected #{Token::Kind::Function} but found #{reader.peek.kind}")
      end

      {AST::FFI.new(string, function), reader}
    end

    def self.parse_function_body(reader : Reader)
      {Array(AST::Node), Reader}
      body = [] of AST::Node

      while reader.peek.kind != Token::Kind::CurlyClose
        consumed = reader.consume
        case consumed.kind
        when Token::Kind::EOF
          abort("error: expected #{Token::Kind::CurlyClose} but found #{consumed.kind}")
        when Token::Kind::Number
          body.push(parse_number(consumed))
        end
      end
      reader.consume

      {body, reader}
    end

    def self.parse_function(reader : Reader)
      {AST::Function, Reader}
      if reader.peek.kind == Token::Kind::Symbol
        name = parse_symbol(reader.consume)
      else
        abort("error: expected #{Token::Kind::Symbol} but found #{reader.peek.kind}")
      end

      params = [] of AST::Parameter
      if reader.peek.kind == Token::Kind::ParenOpen
        reader.consume
        while reader.peek.kind != Token::Kind::ParenClose
          consumed = reader.consume
          case consumed.kind
          when Token::Kind::EOF
            abort("error: expected #{Token::Kind::ParenClose} but found #{consumed.kind}")
          when Token::Kind::Symbol
            params.push(AST::Parameter.new(parse_symbol(consumed)))
          end
        end
        reader.consume
      end

      if reader.peek.kind == Token::Kind::CurlyOpen
        reader.consume
        body, reader = parse_function_body(reader)
      else
        abort("error: expected #{Token::Kind::CurlyOpen} but found #{reader.peek.kind}")
      end

      {AST::Function.new(name, params, body), reader}
    end

    def self.parse(tokens : Array(Token::Token))
      Array(AST::Node)
      ast = [] of AST::Node
      reader = Reader.new(tokens)

      while !reader.eof?
        consumed = reader.consume
        case consumed.kind
        when Token::Kind::Function
          f, reader = parse_function(reader)
          ast.push(f)
        when Token::Kind::FFI
          ffi, reader = parse_ffi(reader)
          ast.push(ffi)
        when Token::Kind::DoubleQuote
          s, reader = parse_string(reader)
          ast.push(s)
        when Token::Kind::Number
          ast.push(parse_number(consumed))
        end
      end

      ast
    end
  end
end
