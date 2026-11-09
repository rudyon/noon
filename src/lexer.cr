module Noon
  module Lexer
    struct Scanner
      property source, pos

      def initialize(@source : String)
        @pos = 0
      end

      def peek
        Char
        @source[@pos]
      end

      def advance
        @pos += 1
      end

      def consume
        Char
        c = peek()
        advance()
        c
      end

      def eof?
        @pos >= @source.size
      end
    end

    def self.match(scanner : Scanner, predicate : Char -> Bool)
      {String, Scanner}
      s = [] of Char

      while predicate.call(scanner.peek)
        s.push(scanner.consume)
      end

      {s.join, scanner}
    end

    def self.tokenize(source : String)
      Array(Token::Token)
      tokens = [] of Token::Token
      scanner = Scanner.new(source)

      while !scanner.eof?
        consumed = scanner.consume
        case consumed
        when 'f'
          if scanner.peek.whitespace? || scanner.eof?
            tokens.push(Token::Token.new(Token::Kind::Function, "f"))
          elsif scanner.peek == 'f' # TODO: find a more elegant way to do this
            scanner.consume
            if scanner.peek == 'i'
              scanner.consume
              tokens.push(Token::Token.new(Token::Kind::FFI, "ffi"))
            else
              abort("error: no keyword named ff. did you mean ffi?")
            end
          end
        when '{'
          tokens.push(Token::Token.new(Token::Kind::CurlyOpen, "{"))
        when '}'
          tokens.push(Token::Token.new(Token::Kind::CurlyClose, "}"))
        when '('
          tokens.push(Token::Token.new(Token::Kind::ParenOpen, "("))
        when ')'
          tokens.push(Token::Token.new(Token::Kind::ParenClose, ")"))
        when '"'
          tokens.push(Token::Token.new(Token::Kind::DoubleQuote, "\""))
        when .number?
          matched, scanner = Lexer.match(scanner, ->(c : Char) { c.number? })
          tokens.push(Token::Token.new(Token::Kind::Number, consumed + matched))
        when .letter?
          matched, scanner = Lexer.match(scanner, ->(c : Char) { c.letter? || c == '_' })
          tokens.push(Token::Token.new(Token::Kind::Symbol, consumed + matched))
        end
      end
      tokens.push(Token::Token.new(Token::Kind::EOF, ""))

      tokens
    end
  end
end
