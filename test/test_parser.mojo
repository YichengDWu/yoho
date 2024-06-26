from yoho import Tokenizer, Parser, Kind
from testing import assert_equal, assert_true


fn test_basic() raises:
    var code: String = "1+2*3"
    var p = Parser(code)

    var t = p._expect["NUMBER"]()
    assert_true(t and t.value()[].text == "1")

    var pos = p._mark()
    assert_true(p._expect["+"]())

    t = p._expect["NUMBER"]()
    assert_true(t and t.value()[].text == "2")
    assert_true(p._expect["*"]())
    var pos2 = p._mark()

    p._reset(pos)
    assert_true(p._expect["+"]())
    assert_true(p._expect["2"]())
    assert_true(p._expect["*"]())
    assert_true(p._expect["3"]())

    p._reset(pos2)
    assert_true(p._expect["3"]())


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
    # print(tree2.value()[])
    # print(tree2.value()[].unparse())

    var node3 = tree2.value()[].args[0]
    assert_equal(node3[].kind, Kind.BinOp)
    var node4 = tree2.value()[].args[1]
    assert_equal(node4[].text, "+")

    assert_equal(tree2.value()[].unparse(), "1-2+3")


fn test_single_char() raises:
    var single_char_ops = List[String](
        "+",
        "-",
        "*",
        "/",
        "(",
        ")",
        ":",
        "|",
        "!",
        "&",
        ",",
        ";",
        "<",
        ">",
        "=",
        ".",
        "%",
        "{",
        "}",
        "~",
        "^",
        "@",
        "[",
        "]",
        "\n",
    )
    for char in single_char_ops:
        var code = "1 " + char[] + " 2"
        var tokenizer = Tokenizer(code)
        var token = tokenizer.bump()
        token = tokenizer.bump()
        assert_equal(token.text, char[])


fn test_assign() raises:
    var code = "a=3"
    var p = Parser(code)
    var tree = p.assignment()
    assert_true(tree)
    print(tree.value()[])
    assert_equal(tree.value()[].kind, Kind.Assign)
    var name = tree.value()[].args[0]
    var value = tree.value()[].args[1]
    assert_equal(name[].text, "a")
    assert_equal(value[].text, "3")
    _ = tree


fn test_functiondef() raises:
    var code = "fn main() -> Int:\n    return 42\n"
    var p = Parser(code)
    var tree = p.function_def()
    assert_true(tree)
    print(tree.value()[])
    assert_equal(tree.value()[].kind, Kind.FunctionDef)
    assert_equal(tree.value()[].text, "main")


def main():
    test_basic()
    test_parser()
    test_single_char()
    test_assign()
    test_functiondef()
