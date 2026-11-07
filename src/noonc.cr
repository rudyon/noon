require "./token"
require "./lexer"

module NoonC
  def self.main
    source = File.read(ARGV[0])
    tokens = Lexer.tokenize(source)

    tokens.each do |token|
      puts token
    end
  end
end

NoonC.main
