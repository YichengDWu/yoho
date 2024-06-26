from testing import assert_equal
from yoho import TokenGenerator, Tokenizer, Kind


fn test_peek_next_char() raises:
    var code = String("\n  1+4*67-(4-5)\n    \n        2+2\n")
    var tokengen = TokenGenerator(code)
    var peeked_char = tokengen.peek_char()
    var next_char = tokengen.next_char()
    var i = 0

    while peeked_char != "":
        assert_equal(peeked_char, next_char, code[i])
        peeked_char = tokengen.peek_char()
        next_char = tokengen.next_char()
        i += 1


fn test_peek_next_token() raises:
    var code = String("\n  1+4*67-(4-5)\n    \n\n        2+2\n\n")
    var tokenizer = Tokenizer(code)
    var peeked_token = tokenizer.peek()
    var next_token = tokenizer.bump()

    while not peeked_token.iseof():
        assert_equal(peeked_token, next_token, peeked_token.text)
        peeked_token = tokenizer.peek()
        next_token = tokenizer.bump()


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


fn test_string() raises:
    # Double quotes
    var code = String('"hello"')
    var tokenizer = Tokenizer(code)
    var token = tokenizer.bump()
    assert_equal(token.text, '"hello"')
    assert_equal(token.kind, Kind.STRING)

    # Single quotes
    code = String("'hello'")
    tokenizer = Tokenizer(code)
    token = tokenizer.bump()
    assert_equal(token.text, "'hello'")
    assert_equal(token.kind, Kind.STRING)


fn test_name() raises:
    var code = String("x-y+z")
    var tokenizer = Tokenizer(code)
    var token = tokenizer.bump()
    assert_equal(token.text, "x")
    assert_equal(token.kind, Kind.NAME)

    token = tokenizer.bump()
    assert_equal(token.text, "-")
    assert_equal(token.kind, Kind.MINUS)

    token = tokenizer.bump()
    assert_equal(token.text, "y")
    assert_equal(token.kind, Kind.NAME)

    token = tokenizer.bump()
    assert_equal(token.text, "+")
    assert_equal(token.kind, Kind.PLUS)

    token = tokenizer.bump()
    assert_equal(token.text, "z")
    assert_equal(token.kind, Kind.NAME)


fn test_double_char() raises:
    var double_char_ops = List[String]("==", "!=", "<=", ">=", "<", ">", "->")

    for op in double_char_ops:
        var code = "1 " + op[] + " 2"
        var tokenizer = Tokenizer(code)
        var token = tokenizer.bump()
        token = tokenizer.bump()
        assert_equal(token.text, op[])


def main():
    test_peek_next_char()
    test_peek_next_token()
    test_single_char()
    test_string()
    test_name()
    test_double_char()
