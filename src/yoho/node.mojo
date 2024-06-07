from .tokenizer import Kind, Span, Token
from .utils import pad, rpad


struct Node(EqualityComparable, CollectionElement, Stringable, Representable):
    var kind: Kind
    var text: String
    var span: Span
    var args: List[Node]

    fn __init__(inout self, owned other: Token):
        self.kind = other.kind
        self.text = other.text
        self.span = other.span
        self.args = List[Node]()

    fn __init__(
        inout self,
        owned kind: Kind,
        owned arg1: Node,
        owned *args: Node,
    ):
        self.kind = kind
        self.text = ""
        self.span = Span(
            arg1.span.start,
            args[len(args) - 1].span.end,
        )
        self.args = List[Node](capacity=len(args) + 1)
        self.args.size = len(args) + 1
        var ptr = self.args.unsafe_ptr()
        ptr.init_pointee_copy(arg1)
        ptr += 1
        for i in range(len(args)):
            ptr.init_pointee_copy(args[i])
            ptr += 1

    fn __copyinit__(inout self, other: Self):
        self.kind = other.kind
        self.text = other.text
        self.span = other.span
        self.args = List[Node](capacity=len(other.args))
        self.args.size = len(other.args)
        var ptr = self.args.unsafe_ptr()
        for i in range(len(other.args)):
            ptr.init_pointee_copy(other.args[i])
            ptr += 1

    fn __moveinit__(inout self, owned other: Self):
        self.kind = other.kind
        self.text = other.text^
        self.span = other.span
        self.args = List[Node](capacity=len(other.args))
        self.args.size = len(other.args)
        var ptr = self.args.unsafe_ptr()
        for i in range(len(other.args)):
            ptr.init_pointee_move(other.args[i])
            ptr += 1

    fn __del__(owned self):
        self.args.clear()

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
            if self.args[i] != other.args[i]:
                return False

        return res

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    @always_inline("nodebug")
    fn isleaf(self) -> Bool:
        return not self.args

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
                line += arg[].to_string[with_text](new_indent)
        return line

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
            self.args.__str__(),
            ")",
        )

    fn iseof(self) -> Bool:
        return self.kind == Kind.ENDMARKER
