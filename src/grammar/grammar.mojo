@value
@register_passable("trivial")
struct GrammarKind(EqualityComparable):
    var value: Int

    alias Grammar = Self(0)
    alias Rule = Self(1)
    alias Rhs = Self(2)
    alias Alt = Self(3)
    alias Items = Self(4)
    alias NamedItem = Self(5)
    alias Repeat0 = Self(6)
    alias Repeat1 = Self(7)
    alias Gather = Self(8)
    alias Group = Self(9)
    alias Atom = Self(10)
    alias Action = Self(11)

    fn __init__(inout self, value: Int):
        self.value = value

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value


@value
struct GrammarNode(
    EqualityComparable, CollectionElement, Stringable, Formattable
):
    var kind: GrammarKind
    var text: String
    var args: List[GrammarNode]

    fn __init__(
        inout self, kind: GrammarKind, text: String, args: List[GrammarNode]
    ):
        self.kind = kind
        self.text = text
        self.args = List[GrammarNode](capacity=len(args))
        for arg in args:
            self.args.append(arg[])

    fn __init__(inout self, kind: GrammarKind, text: String):
        self = Self(kind, text, List[GrammarNode]())

    fn __init__(inout self, kind: GrammarKind, args: List[GrammarNode]):
        self = Self(kind, "", args)

    fn __init(inout self, kind: GrammarKind, text: String, arg: GrammarNode):
        self = Self(kind, text, List[GrammarNode](arg))

    fn __moveinit__(inout self, owned other: GrammarNode):
        self.kind = other.kind
        self.text = other.text^
        self.args = other.args^

    fn __copyinit__(inout self, other: GrammarNode):
        self.kind = other.kind
        self.text = other.text
        self.args = other.args

    fn __del__(owned self):
        self.args.clear()

    fn __eq__(self, other: GrammarNode) -> Bool:
        var res = (
            self.kind == other.kind
            and self.text == other.text
            and len(self.args) == len(other.args)
        )
        if not res:
            return res

        for i in range(len(self.args)):
            res = res and self.args[i] == other.args[i]

        return res

    fn __ne__(self, other: GrammarNode) -> Bool:
        return not self == other

    fn __str__(self) -> String:
        var res = String()
        var fmt = Formatter(res)
        self.format_to(fmt)
        return res

    fn format_to(self, inout fmt: Formatter):
        if self.kind == GrammarKind.Grammar:
            for rule in self.args:
                write_to(fmt, str(rule[]))
        elif self.kind == GrammarKind.Rule:
            write_to(fmt, self.text, ":")
            write_to(fmt, str(self.args[0]))
        elif self.kind == GrammarKind.Rhs:
            if len(self.args) == 1:
                write_to(fmt, str(self.args[0]), "\n")
            else:
                write_to(fmt, "\n")
                for alt in self.args:
                    write_to(fmt, "    |", str(alt[]), "\n")
            write_to(fmt, "\n")
        elif self.kind == GrammarKind.Alt:
            write_to(fmt, str(self.args[0]))
            if len(self.args) == 2:  # print action
                write_to(fmt, str(self.args[1]))
        elif self.kind == GrammarKind.Items:
            for item in self.args:
                write_to(fmt, " ", str(item[]))
        elif self.kind == GrammarKind.Action:
            write_to(fmt, " { ")
            var has_op = len(self.args) == 1
            if has_op:
                write_to(fmt, self.args[0].text)
            write_to(fmt, self.text)
            write_to(fmt, " }")
        elif self.kind == GrammarKind.NamedItem:
            if self.text:
                write_to(fmt, self.text, "=")
            write_to(fmt, str(self.args[0]))
        elif self.kind == GrammarKind.Repeat0:
            write_to(fmt, str(self.args[0]), "*")
        elif self.kind == GrammarKind.Repeat1:
            write_to(fmt, str(self.args[0]), "+")
        elif self.kind == GrammarKind.Gather:
            write_to(fmt, self.text, ".", str(self.args[0]), "+")
        elif self.kind == GrammarKind.Group:
            write_to(fmt, "( ", str(self.args[0]))
            for item in self.args[1:]:
                write_to(fmt, " ", str(item[]))
            write_to(fmt, " )")
        elif self.kind == GrammarKind.Atom:
            write_to(fmt, self.text)


fn Grammar(rules: List[GrammarNode]) -> GrammarNode:
    return GrammarNode(GrammarKind.Grammar, rules)


fn Rule(name: String, rhs: GrammarNode) -> GrammarNode:
    return GrammarNode(GrammarKind.Rule, name, rhs)


fn Rhs(alts: List[GrammarNode]) -> GrammarNode:
    return GrammarNode(GrammarKind.Rhs, alts)


fn Alt(items: GrammarNode, action: Optional[GrammarNode] = None) -> GrammarNode:
    if action:
        return GrammarNode(
            GrammarKind.Alt, List[GrammarNode](items, action.value())
        )
    return GrammarNode(GrammarKind.Alt, items)


fn Items(items: List[GrammarNode]) -> GrammarNode:
    return GrammarNode(GrammarKind.Items, items)


fn NamedItem(item: GrammarNode, name: Optional[String] = None) -> GrammarNode:
    if name:
        return GrammarNode(GrammarKind.NamedItem, name.value(), item)
    return GrammarNode(GrammarKind.NamedItem, "", item)


fn Repeat0(atom: GrammarNode) -> GrammarNode:
    return GrammarNode(GrammarKind.Repeat0, atom.text, atom)


fn Repeat1(atom: GrammarNode) -> GrammarNode:
    return GrammarNode(GrammarKind.Repeat1, atom.text, atom)


fn Gather(sep: String, atom: GrammarNode) -> GrammarNode:
    return GrammarNode(GrammarKind.Gather, sep, atom)


fn Group(items: List[GrammarNode]) -> GrammarNode:
    return GrammarNode(GrammarKind.Group, items)


fn Atom(text: String) -> GrammarNode:
    return GrammarNode(GrammarKind.Atom, text)


fn Action(
    target_atoms: String, op: Optional[GrammarNode] = None
) -> GrammarNode:
    if op:
        return GrammarNode(GrammarKind.Action, target_atoms, op.value())
    return GrammarNode(GrammarKind.Action, target_atoms)
