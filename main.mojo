from sys import argv
from yoho import Parser, CodeGen


fn main() raises:
    if len(argv()) != 2:
        raise Error("Invalid number of arguments")

    var fmt = Formatter.stdout()
    write_to(fmt, ".global  main\n")
    write_to(fmt, "main:\n")
    var parser = Parser(argv()[1])
    var ast = parser.expr()
    var codegen = CodeGen()
    codegen.gen(fmt, ast.value())
    write_to(fmt, "    ret\n")
