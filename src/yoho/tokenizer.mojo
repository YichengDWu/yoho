from .utils import pad, lpad, rpad
from collections import InlineList
from python import Python


@value
struct Kind(EqualityComparable, Representable, Stringable):
    var value: Int

    alias ENDMARKER = Self(0)
    alias NAME = Self(1)
    alias NUMBER = Self(2)
    alias STRING = Self(3)
    alias NEWLINE = Self(4)
    alias INDENT = Self(5)
    alias DEDENT = Self(6)
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
    alias EQEQUAL = Self(27)
    alias NOTEQUAL = Self(28)
    alias LESSEQUAL = Self(29)
    alias GREATEREQUAL = Self(30)
    alias TILDE = Self(31)
    alias CIRCUMFLEX = Self(32)
    alias AT = Self(49)
    alias EXCLAMATION = Self(54)
    alias NL = Self(65)

    # Syntax node kinds
    alias BinOp = Kind(69)
    alias UnaryOp = Self(70)
    alias Compare = Self(71)
    alias Block = Self(72)
    alias Assign = Self(73)
    alias Return = Self(74)
    alias If = Self(75)

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
        elif self == Kind.EQEQUAL:
            return "EQEQUAL"
        elif self == Kind.NOTEQUAL:
            return "NOTEQUAL"
        elif self == Kind.LESSEQUAL:
            return "LESSEQUAL"
        elif self == Kind.GREATEREQUAL:
            return "GREATEREQUAL"
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
        elif self == Kind.NL:
            return "NL"
        elif self == Kind.STRING:
            return "STRING"
        elif self == Kind.NAME:
            return "NAME"
        elif self == Kind.BinOp:
            return "BinOp"
        elif self == Kind.UnaryOp:
            return "UnaryOp"
        elif self == Kind.Compare:
            return "Compare"
        elif self == Kind.Block:
            return "Block"
        elif self == Kind.Assign:
            return "Assign"
        elif self == Kind.Return:
            return "Return"
        elif self == Kind.INDENT:
            return "INDENT"
        elif self == Kind.DEDENT:
            return "DEDENT"
        elif self == Kind.If:
            return "If"
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
    elif kind == "==":
        return Kind.EQEQUAL
    elif kind == "!=":
        return Kind.NOTEQUAL
    elif kind == "<=":
        return Kind.LESSEQUAL
    elif kind == ">=":
        return Kind.GREATEREQUAL
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
    elif s == "NL":
        return Kind.NL
    elif s == "NAME":
        return Kind.NAME
    elif s == "STRING":
        return Kind.STRING
    elif s == "INDENT":
        return Kind.INDENT
    elif s == "DEDENT":
        return Kind.DEDENT

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
    var indents: List[Int]
    var dedents: Int

    fn __init__(inout self, code: String):
        self.code = code
        self.pos = 0
        self.indents = List[Int]()
        self.dedents = 0

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
        var re = Python.import_module("re2")
        var regex_name = re.compile("\\w+")
        var regex_string = re.compile("'.*?'|\".*?\"")
        alias double_char_ops = InlineList[String, 4]("==", "!=", "<=", ">=")
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

        if self.dedents:
            self.dedents -= 1
            return Token(Kind.DEDENT, "", self.pos - 1, self.pos)

        # handle indentation at the beginning of the line
        if self.pos > 0 and self.code[self.pos - 1] == "\n":
            if self.peek_char() == " ":
                return self.handle_indentation()
            elif self.indents:
                return self.handle_indentation()

        var c = self.next_char()
        if c == "":
            return Token(Kind.ENDMARKER, "", self.pos - 1, self.pos - 1)

        # skip whitespaces
        while c == " ":
            c = self.next_char()
        var ord_c = ord(c)
        var next_c = self.peek_char()
        var pos = self.pos - 1

        if c == "":
            return Token(Kind.ENDMARKER, "", pos, pos)
        elif c == "\n":
            if self.code[pos - 1] == "\n":  # TODO： handle"\n   \n"
                return Token(Kind.NL, c, pos, pos + 1)
            else:
                return Token(Kind.NEWLINE, c, pos, pos + 1)
        elif (c + next_c) in double_char_ops:
            self.pos += 1
            return Token(to_kind(c + next_c), c + next_c, pos, pos + 2)
        elif c in single_char_ops:
            return Token(to_kind(c), c, self.pos - 1, self.pos)
        elif isdigit(ord_c):
            var number = String(c)
            var fmt = Formatter(number)
            while isdigit(ord(self.peek_char())):
                write_to(fmt, self.next_char())
            return Token(Kind.NUMBER, number, pos, pos + len(number))
        elif ord_c == 39 or ord_c == 34:
            var m = regex_string.`match`(self.code, pos)
            if m:
                var text = str(m.group(0))
                self.pos = pos + len(text)
                return Token(Kind.STRING, text, pos, self.pos)
            else:
                raise Error("invalid string")
        elif isupper(ord_c) or islower(ord_c) or c == "_":
            var m = regex_name.`match`(self.code, pos)
            if m:
                var text = str(m.group(0))
                self.pos = pos + len(text)
                return Token(Kind.NAME, text, pos, self.pos)
            else:
                raise Error("invalid name")
        else:
            raise Error("invalid character")

    fn handle_indentation(inout self) raises -> Token:
        var indent = 0
        var pos = self.pos
        var c = self.next_char()
        while c == " ":
            indent += 1
            c = self.next_char()
        if c == "\n":  # handle empty line
            return Token(Kind.NL, "\n", self.pos - 1, self.pos)

        # rollback if it's not the end, otherwise emit dedents before the endmarker
        self.pos = self.pos - 1 if self.pos != len(self.code) else self.pos
        if (len(self.indents) == 0 and indent > 0) or indent > self.indents[-1]:
            self.indents.append(indent)
            return Token(Kind.INDENT, String(" ") * indent, pos, pos + indent)
        elif self.indents and indent < self.indents[-1]:
            while self.indents and indent < self.indents[-1]:
                _ = self.indents.pop()
                self.dedents += 1
        return self.next_token()


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
