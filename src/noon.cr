require "option_parser"
require "./token"
require "./type"
require "./lexer"
require "./ast"
require "./parser"
require "./type_checker"
require "./ir"
require "./backend"

module Noon
  def self.main
    emit_ir = false
    output_file = ""
    target = Crystal::TARGET_TRIPLE
    files = [] of String

    OptionParser.parse do |parser|
      parser.banner = "usage: noon [arguments] [FILEs]"

      parser.on("-ir", "emit intermediate represtation") do
        emit_ir = true
      end

      parser.on("-t", "--target TARGET", "specify target triple") do |_target|
        target = _target
      end

      parser.on("-o", "--output FILE", "specify output file") do |file|
        output_file = file
      end

      parser.on("-h", "--help", "show this help") do
        puts parser
        exit(0)
      end

      parser.missing_option do |flag|
        abort("error: #{flag} is missing something")
      end

      parser.invalid_option do |flag|
        abort("error: #{flag} is not valid")
      end

      parser.unknown_args do |args|
        files = args
      end
    end

    if files.size > 1
      abort("error: compiling multiple files isn't support yet")
    elsif files.size == 0
      abort("error: no input files")
    end

    input_file = Path[files[0]]
    abort("error: no such file #{input_file}") unless File.exists?(input_file)

    if output_file == ""
      output_file = File.basename(input_file, input_file.extension)
    end

    source = File.read(input_file)
    tokens = Lexer.tokenize(source)
    ast = Parser.parse(tokens)

    TypeChecker.check(ast)

    ir = IR.lower(ast)

    if emit_ir
      File.write(output_file, IR.to_s(ir))
    else
      bin = Backend.target_triple(target, ir)
      File.write(output_file, bin, perm: 0o755)
    end
  end
end

Noon.main
