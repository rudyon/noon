require "./token"
require "./lexer"
require "./ast"
require "./parser"
require "./ir"

module Noon
  def self.main
    source = File.read(ARGV[0])
    tokens = Lexer.tokenize(source)
    ast = Parser.parse(tokens)
    ir = IR.lower(ast)
    puts IR.to_s(ir)
  end
end

Noon.main
