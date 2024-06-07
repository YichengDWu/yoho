from sys import argv


@value
struct Kind(EqualityComparable):
    var value: Int

    alias PLUS = Kind(0)
    alias MINUS = Kind(1)
    alias NUMBER = Kind(2)
    alias ENDMARKER = Kind(3)

    fn __eq__(self, other: Kind) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Kind) -> Bool:
        return self.value != other.value


@value
struct Token:
    var kind: Kind
    var text: String


struct TokenGenerator:
    var code: String
    var index: Int

    fn __init__(inout self, code: String):
        self.code = code
        self.index = 0

    fn peek_char(inout self) -> String:
        if self.index < len(self.code):
            return self.code[self.index]
        return ""

    fn next_char(inout self) -> String:
        if self.index < len(self.code):
            var c = self.code[self.index]
            self.index += 1
            return c
        return ""

    fn next_token(inout self) raises -> Token:
        var c = self.next_char()
        if c == "":
            return Token(Kind.ENDMARKER, "")

        # skip whitespaces
        while c == " ":
            c = self.next_char()

        if c == "+":
            return Token(Kind.PLUS, "+")
        elif c == "-":
            return Token(Kind.MINUS, "-")
        elif isdigit(ord(c)):
            var number = String(c)
            var fmt = Formatter(number)
            while isdigit(ord(self.peek_char())):
                write_to(fmt, self.next_char())
            return Token(Kind.NUMBER, number)
        elif c == "":
            return Token(Kind.ENDMARKER, "")
        else:
            raise Error("invalid character")


fn main() raises:
    if len(argv()) != 2:
        raise Error("invalid number of arguments")

    var s = argv()[1]
    var tokengen = TokenGenerator(s)
    var token = tokengen.next_token()

    print(".global  main")
    print("main:")
    print("    li a0, ", token.text)

    while True:
        token = tokengen.next_token()
        if token.text == "+":
            print("    addi a0, a0, ", tokengen.next_token().text)
        elif token.text == "-":
            print("    addi a0, a0, ", "-" + tokengen.next_token().text)
        elif token.kind == Kind.ENDMARKER:
            break
        else:
            raise Error("invalid token")

    print("    ret")
