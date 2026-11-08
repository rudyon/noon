require "file_utils"

module Noon
  module Backend
    def self.to_x86_64_unknown_uefi(ir : Array(IR::Operation))
      Bytes
      buffer = IO::Memory.new

      # COFF file header

      # magic number for x86_64
      buffer.write_bytes(0x8664.to_u16)

      # number of sections
      buffer.write_bytes(0x0001.to_u16)

      # file creation timestamp
      ctime = (Time.utc - Time::UNIX_EPOCH).to_seconds
      buffer.write_bytes(ctime)

      # pointer to symbol table
      buffer.write_bytes(0x00000000)

      # number of symbols
      buffer.write_bytes(0x00000000)

      # size of the optional header
      buffer.write_bytes(0x0000.to_u16)

      # characteristics
      buffer.write_bytes(0x0000.to_u16)

      # COFF section header

      # section name
      buffer.write_string("efi_main".to_slice)

      # idg the rest so let's just try setting them all to zero for now
      buffer.write_bytes(0x00000000) # virtual size
      buffer.write_bytes(0x00000000) # virtual address
      buffer.write_bytes(0x00000000) # size of raw data
      buffer.write_bytes(0x00000000) # pointer to raw data
      buffer.write_bytes(0x00000000) # pointer to relocations
      buffer.write_bytes(0x00000000) # pointer to line numbers
      buffer.write_bytes(0x00000000) # number of relocations & number of line numbers
      buffer.write_bytes(0x00000000) # characteristics

      ir.each do |op|
        case op
        when .is_a?(IR::FunctionBegin)
          # do nothing for now, since you can't call functions yet anyway
        when .is_a?(IR::FunctionEnd)
          # do nothing for now, since you can't call functions yet anyway
        when .is_a?(IR::Push)
          buffer.write_byte(0xb8.to_u8)
          buffer.write_bytes(op.value)
        when .is_a?(IR::Return)
          buffer.write_byte(0xc3.to_u8)
        end
      end

      buffer.to_slice
    end
  end
end
