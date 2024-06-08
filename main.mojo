from sys import argv
from yoho import Parser, CodeGen


fn main() raises:
    if len(argv()) != 3:
        raise Error("Invalid number of arguments")

    var assembly = String()
    var fmt = Formatter(assembly)
    write_to(fmt, ".global  main\n")
    write_to(fmt, "main:\n")
    var src = open(argv()[1], "r")
    var code = src.read()
    var parser = Parser(code)
    var ast = parser.parse()
    var codegen = CodeGen()
    if ast:
        codegen.gen(fmt, ast.value())
        write_to(fmt, "    ret\n")
    else:
        raise Error("Invalid expression")
    src.close()
    with open(argv()[2], "w") as dst:
        dst.write(assembly)
