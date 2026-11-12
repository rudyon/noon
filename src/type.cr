module Noon
  module Type
    alias Type = NoonNil | NoonBool | NoonUInt32 | NoonChar8

    enum Annotation : UInt8
      Nil
      Bool
      UInt32
      UInt64
      Char8
      ArrayofNil
      ArrayofBool
      ArrayofUInt32
      ArrayofUInt64
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

      def initialize(@uint : UInt32)
      end
    end

    struct NoonUInt64
      property uint

      def initialize(@uint : UInt64)
      end
    end

    struct NoonChar8
      property char

      def initialize(@char : Char)
      end
    end
  end
end
