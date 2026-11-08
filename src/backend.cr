require "file_utils"

module Noon
  module Backend
    def self.to_x86_64_unknown_uefi(ir : Array(IR::Operation))
      Bytes
      buffer = IO::Memory.new

      ir.each do |op|
        case op
        when .is_a?(IR::FunctionBegin)
          # do nothing for now, since you can't call functions yet anyway
        when .is_a?(IR::FunctionEnd)
          # do nothing for now, since you can't call functions yet anyway
        when .is_a?(IR::Push)
          buffer.write_byte(0xb8.to_u8)
          buffer.write_byte(0x2a.to_u8)
          buffer.write_byte(0x00.to_u8)
          buffer.write_byte(0x00.to_u8)
          buffer.write_byte(0x00.to_u8)
        when .is_a?(IR::Return)
          buffer.write_byte(0xc3.to_u8)
        end
      end

      buffer.to_slice
    end
  end
end
