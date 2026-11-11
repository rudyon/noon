module Noon
  module Token
    enum Kind : UInt8
      EOF
      If
      Type
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
    end

    struct Token
      property kind, lexeme

      def initialize(@kind : Kind, @lexeme : String)
      end
    end
  end
end
