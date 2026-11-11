module Noon
  module Type
    alias Type = NoonNil | NoonBool | NoonUInt32 | NoonChar8

    enum Annotation : UInt8
      Nil
      Bool
      UInt32
      Char8
      ArrayofNil
      ArrayofBool
      ArrayofUInt32
      ArrayofChar8
    end

    struct NoonNil
      def initialize
      end
    end

    struct NoonBool
      property bool

      def initialize(@bool : Bool)
      end
    end

    struct NoonUInt32
      property uint

      def intialize(@uint : UInt32)
      end
    end

    struct NoonChar8
      property char

      def intialize(@char : Char)
      end
    end
  end
end
