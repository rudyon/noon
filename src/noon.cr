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
    File.write("BOOTX64.EFI", pe, perm: 0o755)
  end
end

Noon.main
