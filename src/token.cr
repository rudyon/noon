module Noon
  module Token
    enum Kind : UInt8
      EOF
      Function
      CurlyOpen
      CurlyClose
      Number
      Symbol
    end

    struct Token
      property kind, lexeme

      def initialize(@kind : Kind, @lexeme : String)
      end
    end
  end
end
