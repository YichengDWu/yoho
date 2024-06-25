from yoho.tokenizer import Kind, Span, Token
from yoho.utils import pad, rpad


alias Node = Arc[NodeData]


struct NodeData(EqualityComparable, Movable, Stringable, Representable):
    var kind: Kind
    var text: String
    var span: Span
    var args: List[Arc[NodeData]]

    fn __init__(
        inout self, kind: Kind, text: String, args: List[Arc[NodeData]]
    ):
        self.kind = kind
        self.text = text
        var start = args[0][].span.start
        var end = args[-1][].span.end
        self.span = Span(start, end)
        self.args = args

    fn __init__(inout self, kind: Kind, args: List[Arc[NodeData]]):
        self = Self(kind, "", args)

    fn __init__(inout self, kind: Kind, arg: Arc[NodeData]):
        self = Self(kind, List[Arc[NodeData]](arg))

    fn __init__(inout self, owned other: Token):
        self.kind = other.kind
        self.text = other.text
        self.span = other.span
        self.args = List[Arc[NodeData]]()

    fn __init__(
        inout self,
        owned kind: Kind,
        owned arg: Arc[NodeData],
        owned *args: Arc[NodeData],
    ):
        self.kind = kind
        self.text = ""
        var start = arg[].span.start
        var arg_last = args[len(args) - 1]
        var end = arg_last[].span.end

        self.span = Span(start, end)
        self.args = List[Node](capacity=len(args) + 1)
        self.args.append(arg)
        for i in range(len(args)):
            self.args.append(args[i])

    fn __moveinit__(inout self, owned other: Self):
        self.kind = other.kind
        self.text = other.text^
        self.span = other.span
        self.args = other.args^

    fn __eq__(self, other: Self) -> Bool:
        var res = (
            self.kind == other.kind
            and self.text == other.text
            and self.span == other.span
            and len(self.args) == len(other.args)
        )
        if not res:
            return res

        for i in range(len(self.args)):
            if self.args[i][] != other.args[i][]:
                return False

        return res

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    @always_inline("nodebug")
    fn isleaf(self) -> Bool:
        return not self.args

    @always_inline("nodebug")
    fn iseof(self) -> Bool:
        return self.kind == Kind.ENDMARKER

    fn to_string[with_text: Bool = True](self, indent: Int = 0) -> String:
        var textstr = repr(self.text) if self.isleaf() else self.text

        @parameter
        if with_text:
            textstr = pad(textstr, 8, 12) + String("┃  ")

        var indentstr = String(" ") * indent
        var spanstr = pad(str(self.span), 10, 16) + "┃"

        var line = String.format_sequence(
            spanstr,
            textstr,
            indentstr,
            str(self.kind),
        )
        line = rpad(line, 70)
        if self.isleaf():
            line += "✔\n"
        else:
            line += "\n"
            var new_indent = indent + 2
            for arg in self.args:
                line += arg[][].to_string[with_text](new_indent)
        return line

    @staticmethod
    fn to_string(list: List[Arc[NodeData]]) -> String:
        var res = String()
        var fmt = Formatter(res)
        for node in list:
            write_to(fmt, Self.to_string(node[][]))
        return res

    fn __str__(self) -> String:
        return self.to_string[True]()

    fn __repr__(self) -> String:
        return String.format_sequence(
            "Node(",
            "kind=",
            repr(self.kind),
            ", text=",
            repr(self.text),
            ", span=",
            str(self.span),
            ", args=",
            Self.to_string(self.args),
            ")",
        )

    fn unparse(self) -> String:
        var res = String()
        var fmt = Formatter(res)
        self.format_to(fmt)
        return res

    fn format_to(self, inout fmt: Formatter):
        for arg in self.args:
            if len(arg[][].args) == 0:
                arg[][].text.format_to(fmt)
            else:
                arg[][].format_to(fmt)
