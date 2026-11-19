struct Lexer {
    source: Vec<char>,
    pos: usize,
}

impl Lexer {
    fn eof(&self) -> bool {
        self.pos >= self.source.len()
    }

    fn skip_whitespace(&mut self) {
        while !self.eof() && self.source[self.pos].is_whitespace() {
            self.pos += 1;
        }
    }

    fn next(&mut self) -> Token {
        self.skip_whitespace();

        if self.eof() {
            return Token {
                kind: TokenKind::EOF,
                lexeme: String::new(),
            };
        }

        let mut s = String::new();
        while !self.eof() && !self.source[self.pos].is_whitespace() {
            s.push(self.source[self.pos]);
            self.pos += 1;
        }

        Token {
            kind: TokenKind::Identifier,
            lexeme: s,
        }
    }
}

#[derive(Debug, PartialEq)]
enum TokenKind {
    EOF,
    Identifier,
}

#[derive(Debug)]
struct Token {
    kind: TokenKind,
    lexeme: String,
}

pub fn lex(source: String) {
    let mut lexer = Lexer {
        source: source.chars().collect(),
        pos: 0,
    };

    let mut tokens = Vec::new();

    loop {
        let token: Token = lexer.next();
        let is_eof = token.kind == TokenKind::EOF;
        tokens.push(token);
        if is_eof {
            break;
        }
    }

    println!("{:?}", tokens)
}
