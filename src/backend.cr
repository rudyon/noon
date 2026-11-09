module Noon
  module Backend
    def self.to_pe(binary : Bytes)
      Bytes
      buffer = IO::Memory.new

      # MS-DOS stub

      buffer.write_bytes(0x5a4d.to_u16) # magic

      spacing_bytes = 58
      while spacing_bytes > 0
        buffer.write_byte(0x00.to_u8)
        spacing_bytes -= 1
      end

      buffer.write_bytes(64.to_u32) # e_lfanew

      # PE header

      buffer.write("PE\0\0".to_slice)   # magic
      buffer.write_bytes(0x8664.to_u16) # machine architecture
      buffer.write_bytes(1.to_u16)      # number of sections
      ctime = (Time.utc - Time::UNIX_EPOCH).to_seconds
      buffer.write_bytes(ctime.to_u32) # file creation timestamp

      spacing_bytes = 8
      while spacing_bytes > 0
        buffer.write_byte(0x00.to_u8)
        spacing_bytes -= 1
      end

      buffer.write_bytes(0x00f0.to_u16) # size of optional header
      buffer.write_bytes(0x0002.to_u16) # characteristics

      # PE32+ optional header

      buffer.write_bytes(0x020b.to_u16) # magic
      buffer.write_bytes(0x0000.to_u16) # linker version
      code_size = (binary.size + 511) & ~511
      buffer.write_bytes(code_size.to_u32) # code size

      spacing_bytes = 8
      while spacing_bytes > 0
        buffer.write_byte(0x00.to_u8)
        spacing_bytes -= 1
      end

      entry_point_rva = 0x1000
      buffer.write_bytes(entry_point_rva.to_u32)
      buffer.write_bytes(0x00001000.to_u32) # base of code
      buffer.write_bytes(0x00100000.to_u64) # image base
      buffer.write_bytes(4096.to_u32)       # section alignment
      buffer.write_bytes(512.to_u32)        # file alignment

      spacing_bytes = 16
      while spacing_bytes > 0
        buffer.write_byte(0x00.to_u8)
        spacing_bytes -= 1
      end

      image_size = (binary.size + (0x1000 - 1)) & ~(0x1000 - 1)
      image_size += entry_point_rva
      buffer.write_bytes(image_size.to_u32) # size of image
      buffer.write_bytes(512.to_u32)        # size of headers
      buffer.write_bytes(0x00000000.to_u32) # checksum
      buffer.write_bytes(10.to_u16)         # subsystem

      spacing_bytes = 38
      while spacing_bytes > 0
        buffer.write_byte(0x00.to_u8)
        spacing_bytes -= 1
      end

      buffer.write_bytes(16.to_u32) # number of data directories

      spacing_bytes = 128
      while spacing_bytes > 0
        buffer.write_byte(0x00.to_u8)
        spacing_bytes -= 1
      end

      # section header

      buffer.write(".text\0\0\0".to_slice)   # section name
      buffer.write_bytes(binary.size.to_u32) # virtual size
      buffer.write_bytes(0x1000.to_u32)      # virtual address
      buffer.write_bytes(code_size.to_u32)   # size of raw data
      buffer.write_bytes(512.to_u32)         # pointer to raw data

      spacing_bytes = 12
      while spacing_bytes > 0
        buffer.write_byte(0x00.to_u8)
        spacing_bytes -= 1
      end

      buffer.write_bytes(0x60000020.to_u32) # characteristics

      spacing_bytes = 144
      while spacing_bytes > 0
        buffer.write_byte(0x00.to_u8)
        spacing_bytes -= 1
      end

      buffer.write(binary)

      spacing_bytes = code_size - binary.size
      while spacing_bytes > 0
        buffer.write_byte(0x00.to_u8)
        spacing_bytes -= 1
      end

      buffer.to_slice
    end

    def self.to_x86_64(ir : Array(IR::Operation))
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
          buffer.write_bytes(op.value)
        when .is_a?(IR::Return)
          buffer.write_byte(0xc3.to_u8)
        end
      end

      buffer.to_slice
    end
  end
end
