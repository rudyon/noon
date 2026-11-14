module Noon
  module Type
    alias Type = NoonNil | NoonVoid | NoonBool | NoonUInt32 | NoonChar8 | NoonNever | NoonArray | NoonPointer | NoonDerived

    enum Annotation : UInt8
      Nil
      Void
      Bool
      UInt32
      UInt64
      Int32
      Int64
      Char8
      Char16
      Never
      Array
      Pointer
      Derived
    end

    struct NoonNil
      def initialize
      end
    end

    struct NoonVoid
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

    struct NoonInt32
      property int

      def initialize(@int : Int32)
      end
    end

    struct NoonInt64
      property int

      def initialize(@int : Int64)
      end
    end

    struct NoonChar8
      property char

      def initialize(@char : Char)
      end
    end


    struct NoonChar16
      property char

      def initialize(@char : UInt16)
      end
    end

    struct NoonNever
      def initialize
      end
    end

    struct NoonArray
      property type, value

      def initialize(@type : Type::Annotation, @value : Array)
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
