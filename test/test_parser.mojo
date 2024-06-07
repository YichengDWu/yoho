from yoho import Tokenizer, Parser, Kind
from testing import assert_equal, assert_true


fn test_basic() raises:
    var code: String = "1+2*3"
    var p = Parser(code)

    var t = p.expect["NUMBER"]()
    assert_true(t and t.value().text == "1")

    var pos = p.mark()
    assert_true(p.expect["+"]())

    t = p.expect["NUMBER"]()
    assert_true(t and t.value().text == "2")
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
    print(tree.value())

    assert_true(tree)
    assert_equal(tree.value().args[0].text, "1")
    assert_equal(tree.value().args[1].text, "-")
    assert_equal(tree.value().kind, Kind.BinOp)


def main():
    test_basic()
    test_parser()
