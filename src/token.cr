module Noon
  module Token
    enum Kind : UInt8
      EOF
      If
      Type
      True
      Struct
      Function
      FFI
      CurlyOpen
      CurlyClose
      ParenOpen
      ParenClose
      BracketOpen
      BracketClose
      DoubleQuote
      Backslash
      Asterisk
      Newline
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
