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
      AST::UInteger8
      if !token.lexeme.to_u8?
        abort("error: only 8-bit unsigned integers supported for now")
      end

      AST::UInteger8.new(token.lexeme.to_u8)
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

      if reader.peek.kind == Token::Kind::CurlyOpen
        reader.consume
        body, reader = parse_function_body(reader)
      else
        abort("error: expected #{Token::Kind::CurlyOpen} but found #{reader.peek.kind}")
      end

      {AST::Function.new(name, body), reader}
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
        when Token::Kind::Number
          ast.push(parse_number(consumed))
        end
      end

      ast
    end
  end
end
