from sys import argv
from yoho import Parser, CodeGen


fn main() raises:
    if len(argv()) != 3:
        raise Error("Invalid number of arguments")

    var assembly = String()
    var fmt = Formatter(assembly)

    with open(argv()[1], "r") as src:
        var code = src.read()
        var parser = Parser(code)
        var ast = parser.parse()
        var codegen = CodeGen()
        if ast:
            codegen.build(fmt, ast.take())
        else:
            raise Error("Invalid expression")
    with open(argv()[2], "w") as dst:
        dst.write(assembly)
