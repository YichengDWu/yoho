from sys import argv
from grammar import ParserGenerator


fn main() raises:
    var f = open(argv()[1], "r")
    var grammar = f.read()
    var parser_generator = ParserGenerator(grammar)
    var s = String()
    var fmt = Formatter(s)
    parser_generator.generate(fmt)
    with open(argv()[2], "w") as f:
        f.write(s)
