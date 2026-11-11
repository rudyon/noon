module Noon
  module Backend
    struct Target
      property triple, c_abi, uefi_abi

      def initialize(@triple : String)
        case @triple
        when "x86_64-unknown-uefi"
          @c_abi = "UEFI"
          @uefi_abi = "UEFI"
        else
          abort("error: #{@triple} target is not supported")
        end
      end

      def c_abi
        @c_abi
      end

      def uefi_abi?
        @uefi_abi
      end
    end

    def self.compile(target_triple : String, ir : Array(IR::Operation))
      target = Target.new(target_triple)
      case target_triple
      when "x86_64-unknown-uefi"
        binary, functions = compile_x86_64(ir, target)
        format_uefi(binary, functions)
      end
    end

    def self.format_uefi(binary : Bytes, functions : Hash(String, Int32))
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

      entry_point_rva = functions["efi_main"]?
      if !entry_point_rva
        abort("error: couldn't find efi_main entry point for x86_64-unknown-uefi")
      end
      entry_point_rva += 0x1000
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

      image_size = ((0x1000 + binary.size) + (0x1000 - 1)) & ~(0x1000 - 1)
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

    def self.compile_x86_64(ir : Array(IR::Operation), target : Target)
      {Bytes, Hash(String, Int32)}
      buffer = IO::Memory.new
      function = IO::Memory.new
      functions = [] of IO::Memory
      function_names = [] of String
      function_addresses = [] of Int32
      function_call_names = [] of String
      function_call_addresses = [] of Int32

      abi = "Noon"
      in_function = false

      ir.each do |op|
        case op
        when IR::FunctionBegin
          function = IO::Memory.new
          function_names.push(op.name)
          in_function = true

          function.write_byte(0x55.to_u8) # push rbp

          # mov rbp, rsp
          function.write_byte(0x48.to_u8)
          function.write_bytes(0xe589.to_u16)
        when IR::FunctionEnd
          if in_function
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
        when IR::Parameter
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
        when IR::FFI
          abi = op.string

          case abi
          when "C"
            abi = target.c_abi
          when "UEFI"
            abi = target.uefi_abi?
          else
            abort("error: unsupported ABI for #{target.triple}")
          end
        when IR::Call
          function_call_names.push(op.name)

          if in_function
            # jmp rel32
            function.write_byte(0xe8.to_u8)
            function_call_addresses.push(function.pos)
            function.write_bytes(0.to_u32)

            if op.params > 0
              function.write_bytes(0x8348.to_u16) # add
              function.write_byte(0xc4.to_u8)     # rsp
              function.write_byte((8 * op.params).to_u8)
            end
          else
            # jmp rel32
            buffer.write_byte(0xe8.to_u8)
            function_call_addresses.push(buffer.pos)
            buffer.write_bytes(0.to_u32)

            if op.params > 0
              buffer.write_bytes(0x8348.to_u16) # add
              buffer.write_byte(0xc4.to_u8)     # rsp
              buffer.write_byte((8 * op.params).to_u8)
            end
          end
        when IR::PushParam
          if in_function
            function.write_bytes(0x75FF.to_u16) # push qword
            function.write_byte((16 + (8 * op.index)).to_u8)
          else
            abort("error: compiler error")
          end
        when IR::PushSymbol
          # TODO: support pushing of symbols aka variables basically
        when IR::PushValue
          if in_function
            # push imm32
            function.write_byte(0x68.to_u8)
            function.write_bytes(op.value.to_u32)
          else
            # push imm32
            buffer.write_byte(0x68.to_u8)
            buffer.write_bytes(op.value.to_u32)
          end
        when IR::PopReturn
          if in_function
            function.write_byte(0x58.to_u8) # pop rax
          else
            buffer.write_byte(0x58.to_u8) # pop rax
          end
        when IR::Return
          buffer.write_byte(0xc3.to_u8) # ret
        end
      end

      functions.each do |f|
        function_addresses.push(buffer.pos)
        buffer.write(f.to_slice)
      end

      function_hash = Hash.zip(function_names, function_addresses)
      function_call_hash = Hash.zip(function_call_names, function_call_addresses)

      f_call_i = 0
      while f_call_i < function_call_hash.size
        f_call_name, f_call_addr = function_call_hash.to_a[f_call_i]
        buffer.seek(f_call_addr, IO::Seek::Set)
        buffer.write_bytes(function_hash[f_call_name] - (f_call_addr + 4))
        f_call_i += 1
      end

      {buffer.to_slice, function_hash}
    end
  end
end
