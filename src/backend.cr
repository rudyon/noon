module Noon
  module Backend
    def self.to_asm(ir : Array(IR::Operation)) # this entire function is temporary
      String
      s = "BITS 64\nORG 0x7c00\n\nstart:\n"

      ir.each do |op|
        case op
        when .is_a?(IR::FunctionBegin)
          # do nothing for now, since you can't call functions yet anyway
        when .is_a?(IR::FunctionEnd)
          # do nothing for now, since you can't call functions yet anyway
        when .is_a?(IR::Push)
          s += "\tmov rdi, #{op.value}\n"
        when .is_a?(IR::Return)
          s += "\tmov rax, 60\n"
        end
      end
      s += "\tjmp $\n" # so we now it's working

      s
    end
  end
end
