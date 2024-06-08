from grammar import GrammarParser
from yoho import TokenGenerator
from testing import assert_equal, assert_true
from yoho.tokenizer import K


fn test_grammar_parser() raises:
    var f = open("./calc.gram", "r")
    var grammar = f.read()
    var parser = GrammarParser(grammar)
    var tree = parser.start()

    assert_true(tree)
    assert_equal(str(tree.value()), grammar)
    print(tree.value())
    f.close()


def main():
    test_grammar_parser()
