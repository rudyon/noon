module Noon
  module Parser
    def self.parse_number(token : Token::Token)
      AST::NoonInt
      AST::NoonInt.new(token.lexeme.to_i)
    end

    def self.parse_symbol(token : Token::Token)
      String
      token.lexeme
    end

    def self.parse_function_body(tokens : Array(Token::Token))
      Array(AST::Node)
      body = [] of AST::Node

      cursor = 0
      while cursor < tokens.size && tokens[cursor].kind != Token::Kind::CurlyClose
        case tokens[cursor].kind
        when Token::Kind::EOF
          abort("error: expected '}' but found EOF")
        when Token::Kind::Number
          body.push(parse_number(tokens[cursor]))
        end
        cursor += 1
      end
      body
    end

    def self.parse_function(tokens : Array(Token::Token))
      AST::Function
      if tokens[0].kind != Token::Kind::Symbol
        abort("error: expected function name but found #{tokens[0].kind}")
      end

      name = parse_symbol(tokens[0])

      if tokens[1].kind != Token::Kind::CurlyOpen
        abort("error: expected '{' but found #{tokens[1].kind}")
      end

      body = parse_function_body(tokens[2..])

      AST::Function.new(name, body)
    end

    def self.parse(tokens : Array(Token::Token))
      Array(AST::Node)
      ast = [] of AST::Node

      cursor = 0
      while cursor < tokens.size
        case tokens[cursor].kind
        when Token::Kind::Function
          ast.push(parse_function(tokens[cursor + 1..]))
        end
        cursor += 1
      end

      ast
    end
  end
end
