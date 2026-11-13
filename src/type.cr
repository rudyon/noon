module Noon
  module Type
    alias Type = NoonNil | NoonBool | NoonUInt32 | NoonChar8 | NoonNever | NoonArray | NoonPointer | NoonDerived

    enum Annotation : UInt8
      Nil
      Bool
      UInt32
      UInt64
      Char8
      Never
      Array
      Pointer
      Derived
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

    struct NoonNever
      def initialize
      end
    end

    struct NoonArray
      property type

      def initialize(@type : Type::Annotation)
      end
    end

    struct NoonPointer
      property pointer

      def initialize(@pointer : Pointer)
      end
    end

    struct NoonDerived
      property name

      def initialize(@name : String)
      end
    end
  end
end
