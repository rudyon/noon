module Noon
  module Debug
    def self.print_tokens(tokens : Array(Token::Token))
      tokens.each do |t|
        if t.kind == Token::Kind::EOF
          print "EOF"
        else
          print "#{t.kind} \"#{t.lexeme}\", "
          if t.lexeme == "\\n"
            print "\n"
          end
        end
      end
      print "\n"
    end
  end
end
