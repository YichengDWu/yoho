from .utils import pad, lpad, rpad
from collections import InlineList


@value
struct Kind(EqualityComparable, Representable, Stringable):
    var value: Int

    alias ENDMARKER = Self(0)
    alias NUMBER = Self(2)
    alias NEWLINE = Self(4)
    alias LPAR = Self(7)
    alias RPAR = Self(8)
    alias LSQB = Self(9)
    alias RSQB = Self(10)
    alias COLON = Self(11)
    alias COMMA = Self(12)
    alias SEMI = Self(13)
    alias PLUS = Self(14)
    alias MINUS = Self(15)
    alias STAR = Self(16)
    alias SLASH = Self(17)
    alias VBAR = Self(18)
    alias AMPER = Self(19)
    alias LESS = Self(20)
    alias GREATER = Self(21)
    alias EQUAL = Self(22)
    alias DOT = Self(23)
    alias PERCENT = Self(24)
    alias LBRACE = Self(25)
    alias RBRACE = Self(26)
    alias TILDE = Self(31)
    alias CIRCUMFLEX = Self(32)
    alias AT = Self(49)
    alias EXCLAMATION = Self(54)

    # Syntax node kinds
    alias BinOp = Kind(69)

    fn __eq__(self, other: Kind) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Kind) -> Bool:
        return self.value != other.value

    fn __str__(self) -> String:
        if self == Kind.PLUS:
            return "PLUS"
        elif self == Kind.MINUS:
            return "MINUS"
        elif self == Kind.STAR:
            return "STAR"
        elif self == Kind.SLASH:
            return "SLASH"
        elif self == Kind.LPAR:
            return "LPAR"
        elif self == Kind.RPAR:
            return "RPAR"
        elif self == Kind.COMMA:
            return "COMMA"
        elif self == Kind.SEMI:
            return "SEMI"
        elif self == Kind.LSQB:
            return "LSQB"
        elif self == Kind.RSQB:
            return "RSQB"
        elif self == Kind.COLON:
            return "COLON"
        elif self == Kind.VBAR:
            return "VBAR"
        elif self == Kind.AMPER:
            return "AMPER"
        elif self == Kind.LESS:
            return "LESS"
        elif self == Kind.GREATER:
            return "GREATER"
        elif self == Kind.EQUAL:
            return "EQUAL"
        elif self == Kind.DOT:
            return "DOT"
        elif self == Kind.PERCENT:
            return "PERCENT"
        elif self == Kind.LBRACE:
            return "LBRACE"
        elif self == Kind.RBRACE:
            return "RBRACE"
        elif self == Kind.TILDE:
            return "TILDE"
        elif self == Kind.CIRCUMFLEX:
            return "CIRCUMFLEX"
        elif self == Kind.AT:
            return "AT"
        elif self == Kind.EXCLAMATION:
            return "EXCLAMATION"
        elif self == Kind.NUMBER:
            return "NUMBER"
        elif self == Kind.ENDMARKER:
            return "ENDMARKER"
        elif self == Kind.NEWLINE:
            return "NEWLINE"
        elif self == Kind.BinOp:
            return "BinOp"
        return "UNKNOWN"

    fn __repr__(self) -> String:
        return String.format_sequence(
            "Kind(",
            str(self),
            ")",
        )


fn to_kind(kind: String) raises -> Kind:
    if kind == "+":
        return Kind.PLUS
    elif kind == "-":
        return Kind.MINUS
    elif kind == "*":
        return Kind.STAR
    elif kind == "/":
        return Kind.SLASH
    elif kind == "(":
        return Kind.LPAR
    elif kind == ")":
        return Kind.RPAR
    elif kind == ",":
        return Kind.COMMA
    elif kind == ";":
        return Kind.SEMI
    elif kind == "[":
        return Kind.LSQB
    elif kind == "]":
        return Kind.RSQB
    elif kind == ":":
        return Kind.COLON
    elif kind == "|":
        return Kind.VBAR
    elif kind == "&":
        return Kind.AMPER
    elif kind == "<":
        return Kind.LESS
    elif kind == ">":
        return Kind.GREATER
    elif kind == "=":
        return Kind.EQUAL
    elif kind == ".":
        return Kind.DOT
    elif kind == "%":
        return Kind.PERCENT
    elif kind == "{":
        return Kind.LBRACE
    elif kind == "}":
        return Kind.RBRACE
    elif kind == "~":
        return Kind.TILDE
    elif kind == "^":
        return Kind.CIRCUMFLEX
    elif kind == "@":
        return Kind.AT
    elif kind == "!":
        return Kind.EXCLAMATION
    elif kind == "\n":
        return Kind.NEWLINE
    else:
        raise Error("invalid kind")


fn K[s: StringLiteral]() raises -> Optional[Kind]:
    @parameter
    if s == "ENDMARKER":
        return Kind.ENDMARKER
    elif s == "NUMBER":
        return Kind.NUMBER
    elif s == "NEWLINE":
        return Kind.NEWLINE
    elif s == "LPAR":
        return Kind.LPAR
    elif s == "RPAR":
        return Kind.RPAR
    elif s == "PLUS":
        return Kind.PLUS
    elif s == "MINUS":
        return Kind.MINUS
    elif s == "STAR":
        return Kind.STAR
    elif s == "SLASH":
        return Kind.SLASH

    return None


@value
struct Span(EqualityComparable, Stringable, Representable):
    var start: Int
    var end: Int

    fn __init__(inout self, start: Int, end: Int):
        self.start = start
        self.end = end

    fn __eq__(self, other: Self) -> Bool:
        return self.start == other.start and self.end == other.end

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __repr__(self) -> String:
        return String.format_sequence(
            "Span(start=",
            str(self.start),
            "end=",
            str(self.end),
            ")",
        )

    fn __str__(self) -> String:
        return String.format_sequence(
            str(self.start),
            ":",
            str(self.end),
        )


@value
struct Token:
    var kind: Kind
    var text: String
    var span: Span

    fn __init__(
        inout self,
        kind: Kind,
        text: String,
        start: Int,
        end: Int,
    ):
        self.kind = kind
        self.text = text
        self.span = Span(start, end)

    fn __init__(inout self, kind: Kind, text: String, span: Span):
        self.kind = kind
        self.text = text
        self.span = span

    fn __eq__(self, other: Token) -> Bool:
        return self.kind == other.kind and self.text == other.text

    fn __ne__(self, other: Token) -> Bool:
        return not self == other

    fn __str__(self) -> String:
        var spanstr = pad(str(self.span), 4, 8) + "┃  "
        var kindstr = rpad(str(self.kind), 16)
        var line = String.format_sequence(
            spanstr,
            kindstr,
            repr(self.text),
        )
        return line

    fn __repr__(self) -> String:
        return String.format_sequence(
            "Token(",
            "kind=",
            repr(self.kind),
            ", text=",
            repr(self.text),
            ", span=",
            str(self.span),
            ")",
        )

    fn iseof(self) -> Bool:
        return self.kind == Kind.ENDMARKER


@value
struct TokenGenerator:
    var code: String
    var pos: Int

    fn __init__(inout self, code: String):
        self.code = code
        self.pos = 0

    fn peek_char(inout self) -> String:
        if self.pos < len(self.code):
            return self.code[self.pos]
        return ""

    fn next_char(inout self) -> String:
        if self.pos < len(self.code):
            var c = self.code[self.pos]
            self.pos += 1
            return c
        return ""

    fn next_token(inout self) raises -> Token:
        alias single_char_ops = InlineList[String, 25](
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

        var c = self.next_char()
        if c == "":
            return Token(Kind.ENDMARKER, "", self.pos - 1, self.pos - 1)

        # skip whitespaces
        while c == " ":
            c = self.next_char()
        if c in single_char_ops:
            return Token(to_kind(c), c, self.pos - 1, self.pos)
        elif isdigit(ord(c)):
            var pos = self.pos - 1
            var number = String(c)
            var fmt = Formatter(number)
            while isdigit(ord(self.peek_char())):
                write_to(fmt, self.next_char())
            return Token(Kind.NUMBER, number, pos, pos + len(number))
        elif c == "":
            return Token(Kind.ENDMARKER, "", self.pos - 1, self.pos - 1)
        else:
            raise Error("invalid character")


@value
struct Tokenizer:
    var tokengen: TokenGenerator
    var tokens: List[Token]
    var pos: Int

    fn __init__(inout self, code: String):
        self.tokengen = TokenGenerator(code)
        self.tokens = List[Token]()
        self.pos = 0

    fn mark(self) -> Int:
        return self.pos

    fn reset(inout self, pos: Int):
        self.pos = pos

    fn bump(inout self) raises -> Token:
        var token = self.peek()
        self.pos += 1
        return token

    fn peek(inout self) raises -> Token:
        if self.pos == len(self.tokens):
            self.tokens.append(self.tokengen.next_token())
        return self.tokens[self.pos]
