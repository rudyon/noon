module NoonC
  module Parser
    def self.parse_number(token : Token::Token)
      AST::NoonInt
      AST::NoonInt.new(token.lexeme.to_i)
    end

    def self.parse_symbol(token : Token::Token)
      String
      token.lexeme
    end

    def self.parse_function(tokens : Array(Token::Token))
      AST::Function
      name = parse_symbol(tokens[0])
      body = [] of AST::Node

      cursor = 1
      while cursor < tokens.size
        case tokens[cursor].kind
        when Token::Kind::Number
          body.push(parse_number(tokens[cursor]))
        end
        cursor += 1
      end

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
