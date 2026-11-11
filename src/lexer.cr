module Noon
  module Lexer
    struct Scanner
      property source, pos

      def initialize(@source : String)
        @pos = 0
      end

      def peek(offset = 0)
        Char
        @source[@pos + offset]
      end

      def look(string : String)
        {String, Bool}
        s = ""

        i = 0
        while i < string.size
          c = peek(i)
          if string[i] != c
            {s, true}
          else
            i += 1
          end
        end

        consume(string.size)

        if peek().whitespace? || eof?()
          {s, false}
        else
          {s, true}
        end
      end

      def advance(steps = 1)
        @pos += steps
      end

      def consume(amount = 0)
        Char
        c = peek(amount)
        advance(amount + 1)
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
        when 'i'
          s, err = scanner.look("f")
          if !err
            tokens.push(Token::Token.new(Token::Kind::If, "i#{s}"))
          elsif s == ""
            break
          else
            abort("error: unexpected i#{s} did you mean if?")
          end
        when 't'
          s, err = scanner.look("ype")
          if !err
            tokens.push(Token::Token.new(Token::Kind::Type, "t#{s}"))
          elsif s == ""
            # continue
          else
            abort("error: no keyword t#{s} did you mean type?")
          end

          s, err = scanner.look("rue")
          if !err
            tokens.push(Token::Token.new(Token::Kind::True, "t#{s}"))
          elsif s == ""
            break
          else
            abort("error: no keyword t#{s} did you mean true?")
          end
        when 's'
          s, err = scanner.look("truct")
          if !err
            tokens.push(Token::Token.new(Token::Kind::Struct, "s#{s}"))
          elsif s == ""
            break
          else
            abort("error: no keyword s#{s} did you mean struct?")
          end
        when 'f'
          if scanner.peek.whitespace? || scanner.eof?
            tokens.push(Token::Token.new(Token::Kind::Function, "f"))
          else
            s, err = scanner.look("fi")
            if !err
              tokens.push(Token::Token.new(Token::Kind::FFI, "f#{s}"))
            elsif s == ""
              break
            else
              abort("error: no keyword f#{s} did you mean ffi?")
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
        when '['
          tokens.push(Token::Token.new(Token::Kind::BracketOpen, "["))
        when ']'
          tokens.push(Token::Token.new(Token::Kind::BracketClose, "]"))
        when '"'
          tokens.push(Token::Token.new(Token::Kind::DoubleQuote, "\""))
        when '\\'
          tokens.push(Token::Token.new(Token::Kind::Backslash, "\\"))
        when '*'
          tokens.push(Token::Token.new(Token::Kind::Asterisk, "*"))
        when '\n'
          tokens.push(Token::Token.new(Token::Kind::Newline, "\\n"))
        when '='
          tokens.push(Token::Token.new(Token::Kind::Equals, "="))
        when '-'
          s, err = scanner.look(">")
          if !err
            tokens.push(Token::Token.new(Token::Kind::RArrow, "-#{s}"))
          elsif s == ""
            break
          else
            abort("error: unexpected -#{s} did you mean ->?")
          end
        when ':'
          tokens.push(Token::Token.new(Token::Kind::Colon, ":"))
        when ','
          tokens.push(Token::Token.new(Token::Kind::Comma, ","))
        when '#'
          tokens.push(Token::Token.new(Token::Kind::Hash, "#"))
        when '!'
          s, err = scanner.look("=")
          if !err
            tokens.push(Token::Token.new(Token::Kind::NotEquals, "!#{s}"))
          elsif s == ""
            break
          else
            abort("error: unexpected !#{s} did you mean !=?")
          end
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
