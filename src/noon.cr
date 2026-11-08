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
    puts Backend.to_asm(ir)
  end
end

Noon.main
