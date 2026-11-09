module Noon
  module Backend
    def self.format(binary : Bytes)
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

    def self.compile(ir : Array(IR::Operation))
      Bytes
      buffer = IO::Memory.new
      function = IO::Memory.new
      functions = [] of IO::Memory

      abi = "Noon"
      in_function = false

      ir.each do |op|
        case op
        when .is_a?(IR::FunctionBegin)
          function = IO::Memory.new
          in_function = true

          function.write_byte(0x55.to_u8) # push rbp

          # mov rbp, rsp
          function.write_byte(0x48.to_u8)
          function.write_bytes(0xe589.to_u16)
        when .is_a?(IR::FunctionEnd)
          if in_function
            function.write_byte(0x58.to_u8) # pop rax

            # mov rsp, rbp
            function.write_byte(0x48.to_u8)
            function.write_bytes(0xec89.to_u16)

            # implicit return (this does not show up in IR)
            function.write_byte(0x5d.to_u8) # pop rbp
            function.write_byte(0xc3.to_u8) # ret

            functions.push(function)
            in_function = false
          else
            abort("error: compiler error")
          end
        when .is_a?(IR::Parameter)
          if in_function
            if abi == "C"
              case op.index
              when 0
                function.write_byte(0x51.to_u8) # push rcx
              when 1
                function.write_byte(0x52.to_u8) # push rdx
              else
                abort("error: compiler error")
              end
            end
          else
            abort("error: compiler error")
          end
        when .is_a?(IR::FFI)
          abi = op.string
        when .is_a?(IR::Push)
          if in_function
            # push imm32
            function.write_byte(0x68.to_u8)
            function.write_bytes(op.value)
          else
            # push imm32
            buffer.write_byte(0x68.to_u8)
            buffer.write_bytes(op.value)
          end
        when .is_a?(IR::Return)
          buffer.write_byte(0x5d.to_u8) # pop rbp
          buffer.write_byte(0xc3.to_u8) # ret
        end
      end

      buffer.write(functions.join.to_slice)

      buffer.to_slice
    end
  end
end
