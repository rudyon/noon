require "./token"
require "./lexer"
require "./ast"
require "./parser"

module Noon
  def self.main
    source = File.read(ARGV[0])
    tokens = Lexer.tokenize(source)
    ast = Parser.parse(tokens)

    if ast.is_a?(Array(AST::Node))
      ast.each do |node|
        puts node
      end
    end
  end
end

Noon.main
