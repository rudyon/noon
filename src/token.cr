module Noon
  module Token
    enum Kind : UInt8
      EOF
      If
      Type
      True
      Struct
      Function
      External
      CurlyOpen
      CurlyClose
      ParenOpen
      ParenClose
      BracketOpen
      BracketClose
      SingleQuote
      DoubleQuote
      Backslash
      Asterisk
      Newline
      Period
      Equals
      RArrow
      Colon
      Comma
      Hash
      Bang
      Number
      Symbol
      NotEquals

      def expression? : Bool
        case self
        when DoubleQuote, Number, Symbol
          true
        else
          false
        end
      end

      def comparison? : Bool
        case self
        when NotEquals
          true
        else
          false
        end
      end
    end

    struct Token
      property kind, lexeme

      def initialize(@kind : Kind, @lexeme : String)
      end
    end
  end
end
