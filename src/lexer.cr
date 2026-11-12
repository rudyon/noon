module Noon
  module Lexer
    struct Scanner
      property source, pos, row

      def initialize(@source : String)
        @pos = 0
        @row = 1
        @col = 0
      end

      def peek(offset = 0)
        Char
        @source[@pos + offset]
      end

      def look(string : String)
        {String, Bool}
        s = ""
        puts "looking for #{trace()}#{string} at #{@row}:#{@col}"

        i = 0
        while i < string.size
          if peek(i).whitespace?
            break
          end

          s += peek(i)
          i += 1
        end

        puts "located #{trace()}#{s}"

        if s == string
          if trace(1).whitespace? || @pos == 0
            if peek(string.size).whitespace? || eof?(string.size)
              consume(string.size)
              {s, false}
            else
              {s, true}
            end
          else
            abort("error: #{loc()} #{trace()}#{s} is not a valid keyword did you mean #{trace()}#{string}?")
          end
        else
          {s, true}
        end
      end

      def advance(steps = 1)
        @pos += steps
        @col += steps
      end

      def consume(amount = 1)
        Char
        advance(amount)
        trace(amount - 1)
      end

      def trace(offset = 0)
        Char
        peek(-(offset + 1))
      end

      def lf
        @row += 1
        @col = 0
      end

      def loc
        String
        "#{@row}:#{@col}"
      end

      def eof?(offset = 0)
        @pos + offset >= @source.size
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

    def self.tokenize_number_or_symbol(token : Char, scanner : Scanner)
      {Token::Token, Scanner}
      case token
      when .number?
        n, scanner = match(scanner, ->(c : Char) { c.number? })
        {Token::Token.new(Token::Kind::Number, token + n), scanner}
      when .letter?, '_', '!', '-'
        s, scanner = match(scanner, ->(c : Char) { c.letter? || c == '_' || c == '!' || c == '-' })
        {Token::Token.new(Token::Kind::Symbol, token + s), scanner}
      else
        abort("error: #{scanner.loc} unrecognized character #{token}")
      end
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
          else
            t, scanner = tokenize_number_or_symbol(consumed, scanner)
            tokens.push(t)
          end
        when 't'
          s, err = scanner.look("ype")
          if !err
            tokens.push(Token::Token.new(Token::Kind::Type, "t#{s}"))
          else
            s, err = scanner.look("rue")
            if !err
              tokens.push(Token::Token.new(Token::Kind::True, "t#{s}"))
            else
              t, scanner = tokenize_number_or_symbol(consumed, scanner)
              tokens.push(t)
            end
          end
        when 's'
          s, err = scanner.look("truct")
          if !err
            tokens.push(Token::Token.new(Token::Kind::Struct, "s#{s}"))
          else
            t, scanner = tokenize_number_or_symbol(consumed, scanner)
            tokens.push(t)
          end
        when 'f'
          s, err = scanner.look("un")
          if !err
            tokens.push(Token::Token.new(Token::Kind::Function, "f#{s}"))
          else
            t, scanner = tokenize_number_or_symbol(consumed, scanner)
            tokens.push(t)
          end
        when 'e'
          s, err = scanner.look("xt")
          if !err
            tokens.push(Token::Token.new(Token::Kind::External, "e#{s}"))
          else
            t, scanner = tokenize_number_or_symbol(consumed, scanner)
            tokens.push(t)
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
        when '\''
          tokens.push(Token::Token.new(Token::Kind::SingleQuote, "'"))
        when '"'
          tokens.push(Token::Token.new(Token::Kind::DoubleQuote, "\""))
        when '\\'
          tokens.push(Token::Token.new(Token::Kind::Backslash, "\\"))
        when '*'
          tokens.push(Token::Token.new(Token::Kind::Asterisk, "*"))
        when '\n'
          scanner.lf
          tokens.push(Token::Token.new(Token::Kind::Newline, "\\n"))
        when '.'
          tokens.push(Token::Token.new(Token::Kind::Period, "."))
        when '-'
          if scanner.peek.whitespace? || scanner.eof?
            tokens.push(Token::Token.new(Token::Kind::Minus, "-"))
          else
            s, err = scanner.look(">")
            if !err
              tokens.push(Token::Token.new(Token::Kind::RArrow, "-#{s}"))
            else
              t, scanner = tokenize_number_or_symbol(consumed, scanner)
              tokens.push(t)
            end
          end
        when '='
          tokens.push(Token::Token.new(Token::Kind::Equals, "="))
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
          else
            tokens.push(Token::Token.new(Token::Kind::Bang, "!#{s}"))
          end
        when .whitespace?
          # do nothing
        else
          t, scanner = tokenize_number_or_symbol(consumed, scanner)
          tokens.push(t)
        end
      end
      tokens.push(Token::Token.new(Token::Kind::EOF, ""))

      tokens
    end
  end
end
