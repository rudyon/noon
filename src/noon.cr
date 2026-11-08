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
    binary = Backend.to_x86_64_unknown_uefi(ir)
    File.write("out.bin", binary)
  end
end

Noon.main
