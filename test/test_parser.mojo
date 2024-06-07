from yoho import Tokenizer, Parser, Kind
from testing import assert_equal, assert_true


fn test_basic() raises:
    var code: String = "1+2*3"
    var p = Parser(code)

    var t = p.expect["NUMBER"]()
    assert_true(t and t.value()[].text == "1")

    var pos = p.mark()
    assert_true(p.expect["+"]())

    t = p.expect["NUMBER"]()
    assert_true(t and t.value()[].text == "2")
    assert_true(p.expect["*"]())
    var pos2 = p.mark()

    p.reset(pos)
    assert_true(p.expect["+"]())
    assert_true(p.expect["2"]())
    assert_true(p.expect["*"]())
    assert_true(p.expect["3"]())

    p.reset(pos2)
    assert_true(p.expect["3"]())


fn test_parser() raises:
    var code = "1-(2+3*2-3/2)"
    var p = Parser(code)
    var tree = p.expr()

    assert_true(tree)
    print(tree.value()[])
    print(tree.value()[].unparse())
    var node = tree.value()[].args[0]
    assert_equal(node[].text, "1")
    var node1 = tree.value()[].args[1]
    assert_equal(node1[].text, "-")
    assert_equal(tree.value()[].kind, Kind.BinOp)

    var code2 = "1-2+3"
    var p2 = Parser(code2)
    var tree2 = p2.expr()
    assert_true(tree2)
    print(tree2.value()[])
    print(tree2.value()[].unparse())

    var node3 = tree2.value()[].args[0]
    assert_equal(node3[].kind, Kind.BinOp)
    var node4 = tree2.value()[].args[1]
    assert_equal(node4[].text, "+")

    assert_equal(tree2.value()[].unparse(), "1-2+3")


def main():
    test_basic()
    test_parser()
