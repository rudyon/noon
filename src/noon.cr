require "./token"
require "./lexer"
require "./ast"
require "./parser"
require "./ir"
require "./backend"

module Noon
  def self.main
    source = File.read(ARGV[0])
    tokens = Lexer.tokenize(source)
    ast = Parser.parse(tokens)
    ir = IR.lower(ast)
    binary = Backend.to_x86_64(ir)
    pe = Backend.to_pe(binary)
    File.write("BOOT_X64.EFI", pe)
    File.chmod("BOOT_X64.EFI", 0o111)
  end
end

Noon.main
