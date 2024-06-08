from .grammar_parser import GrammarNode, GrammarParser
from .grammar import GrammarKind
from python import Python

alias HEADER = """
from .tokenizer import Kind, K, Token, Tokenizer
from .node import NodeData, Node
from collections.dict import KeyElement


@value
struct CacheValue(Representable):
    var node: Optional[Node]
    var endmark: Int

    fn __init__(inout self, node: Optional[Node], endmark: Int):
        self.node = node
        self.endmark = endmark

    fn __repr__(self) -> String:
        return String.format_sequence(
            "(", repr(self.node.value()[]), ", ", self.endmark, ")"
        )


@value
struct CacheKey(KeyElement, Representable):
    var _mark: Int
    var id: StringLiteral  # function + arg

    fn __init__(inout self, _mark: Int, id: StringLiteral):
        self._mark = _mark
        self.id = id

    fn __hash__(self) -> Int:
        return hash(String.format_sequence(self._mark, ",", self.id))

    fn __eq__(self, other: CacheKey) -> Bool:
        return self._mark == other._mark

    fn __ne__(self, other: CacheKey) -> Bool:
        return not self == other

    fn __repr__(self) -> String:
        return String.format_sequence("(", self._mark, ", ", self.id, ")")


fn memoize[
    id: StringLiteral, unmemoized: fn (inout Parser) raises -> Optional[Node]
](inout self: Parser) raises -> Optional[Node]:
    var _mark = self._mark()
    var key = CacheKey(_mark, id)
    var value = self.cache.get(key)
    if value:
        var tree = value.value().node
        var endmark = value.value().endmark
        self._reset(endmark)
        return tree

    var tree = unmemoized(self)
    var endmark = self._mark()
    self.cache[key] = CacheValue(tree, endmark)
    return tree


fn memoize_left_rec[
    id: StringLiteral, unmemoized: fn (inout Parser) raises -> Optional[Node]
](inout self: Parser) raises -> Optional[Node]:
    var _mark = self._mark()
    var key = CacheKey(_mark, id)
    var value = self.cache.get(key)
    if value:
        var tree = value.value().node
        var endmark = value.value().endmark
        self._reset(endmark)
        return tree

    # prime the cache a failure
    self.cache[key] = CacheValue(None, _mark)
    var lastresult = Optional[Node](None)
    var lastmark = _mark

    while True:
        self._reset(_mark)
        var result = unmemoized(self)
        var endmark = self._mark()
        if endmark <= lastmark:
            break
        lastresult, lastmark = result, endmark
        self.cache[key] = CacheValue(lastresult, lastmark)

    self._reset(lastmark)
    var tree = lastresult
    var endmark = _mark

    if tree:
        endmark = self._mark()
    else:
        self._reset(_mark)

    self.cache[key] = CacheValue(tree, endmark)
    return tree

@value
struct Parser:
    var tokenizer: Tokenizer
    var cache: Dict[CacheKey, CacheValue]

    fn __init__(inout self, text: String):
        self.tokenizer = Tokenizer(text)
        self.cache = Dict[CacheKey, CacheValue]()

    fn __init__(inout self, owned tokenizer: Tokenizer):
        self.tokenizer = tokenizer^
        self.cache = Dict[CacheKey, CacheValue]()

    @always_inline
    fn _mark(self) -> Int:
        return self.tokenizer.mark()

    @always_inline
    fn _reset(inout self, _mark: Int):
        self.tokenizer.reset(_mark)

    fn _expect[arg: StringLiteral](inout self) raises -> Optional[Node]:
        fn __expect[
            arg: StringLiteral
        ](inout self: Parser) raises -> Optional[Node]:
            var token = self.tokenizer.peek()
            if token.text == arg:
                return Node(self.tokenizer.bump())
            elif K[arg]() and token.kind == K[arg]().value():
                return Node(self.tokenizer.bump())
            return None

        return memoize[arg, __expect[arg]](self)
"""


fn get_op_names() -> Dict[String, String]:
    var op_names = Dict[String, String]()
    op_names["("] = "lpar"
    op_names[")"] = "rpar"
    op_names[","] = "comma"
    op_names[";"] = "semicolon"
    op_names["+"] = "plus"
    op_names["-"] = "minus"
    op_names["*"] = "star"
    op_names["/"] = "slash"
    op_names["["] = "lsqb"
    op_names["]"] = "rsqb"
    op_names[":"] = "colon"
    op_names["|"] = "vbar"
    op_names["&"] = "ampersand"
    op_names["!"] = "bang"
    op_names["<"] = "less"
    op_names[">"] = "greater"
    op_names["=="] = "eqeq"
    op_names["!="] = "neq"
    op_names["<="] = "leq"
    op_names[">="] = "geq"
    op_names["="] = "equal"
    op_names["."] = "dot"
    op_names["%"] = "percent"
    op_names["{"] = "lbrace"
    op_names["}"] = "rbrace"
    op_names["~"] = "tilde"
    op_names["^"] = "circumflex"
    op_names["@"] = "at"
    return op_names


struct ParserGenerator:
    var grammar: GrammarNode
    var level: Int
    var OP_NAMES: Dict[String, String]
    var top_level_variables: List[String]

    fn __init__(inout self, grammar: String) raises:
        var grammar_parser = GrammarParser(grammar)
        self.grammar = grammar_parser.start().value()
        self.level = 1
        self.OP_NAMES = get_op_names()
        self.top_level_variables = List[String]()

    fn indent(self) -> String:
        return str("    ") * self.level

    fn get_variable_name(
        inout self, item: GrammarNode, postfix: Optional[String] = None
    ) -> String:
        var item_name = item.text  # user defined name
        if item_name:
            return item_name + postfix.value() if postfix else item_name
        var atom = item.args[0]
        var atom_name = atom.text
        var variable_name = atom_name.strip("'").lower()
        variable_name = self.OP_NAMES.get(variable_name, variable_name)
        return variable_name + postfix.value() if postfix else variable_name

    fn generate(inout self, inout fmt: Formatter) raises:
        write_to(fmt, "# This file is generated from the following grammar:\n")
        var grammar = str(self.grammar)
        var lines = grammar.splitlines()
        for line in lines:
            write_to(fmt, "# ", line[], "\n")
        write_to(fmt, HEADER)

        var start_rule_name = self.grammar.args[0].text
        write_to(
            fmt,
            self.indent(),
            "@always_inline\n",
        )
        write_to(
            fmt,
            self.indent(),
            "fn parse(inout self: Parser) raises -> Optional[Node]:\n",
        )
        write_to(fmt, self.indent(), "    return self.", start_rule_name, "()")

        for rule in self.grammar.args:
            self.generate_rule(fmt, rule[])

    fn generate_rule(
        inout self, inout fmt: Formatter, rule: GrammarNode
    ) raises:
        write_to(
            fmt,
            "\n",
            self.indent(),
            "fn ",
            rule.text,
            "(inout self: Parser) raises -> Optional[Node]:\n",
        )
        self.level += 1
        self.generate_unmemoized(fmt, rule)
        if self.is_left_recursive(rule):
            write_to(
                fmt,
                self.indent(),
                'return memoize_left_rec["_',
                rule.text,
                '", _',
                rule.text,
                "](self)\n",
            )
        else:
            write_to(
                fmt,
                self.indent(),
                'return memoize["_',
                rule.text,
                '", _',
                rule.text,
                "](self)\n",
            )
        self.level -= 1

    fn generate_unmemoized(
        inout self, inout fmt: Formatter, rule: GrammarNode
    ) raises:
        write_to(
            fmt,
            self.indent(),
            "fn _",
            rule.text,
            "(inout self: Parser) raises -> Optional[Node]:\n",
        )
        self.level += 1
        write_to(fmt, self.indent(), "var _mark = self._mark()\n\n")
        var rhs = rule.args[0]

        for alt in rhs.args:
            self.generate_alt(fmt, alt[])
        write_to(fmt, self.indent(), "return None\n")
        self.level -= 1
        self.top_level_variables.clear()

    fn generate_alt(inout self, inout fmt: Formatter, alt: GrammarNode) raises:
        var level = self.level
        var items = alt.args[0]
        self.generate_items(fmt, items)

        # Generate action
        write_to(fmt, self.indent(), "return ")
        var has_action = alt.args[-1].kind == GrammarKind.Action
        if has_action:
            self.generate_action(fmt, alt.args[-1], items)
        elif len(items.args) == 1:
            write_to(
                fmt,
                self.get_variable_name(items.args[0], str("_")),
                ".take()\n",
            )
        else:
            raise Error("Must have action for multiple items in an alt")

        self.level = level
        write_to(fmt, self.indent(), "self._reset(_mark)\n\n")

    fn generate_items(
        inout self, inout fmt: Formatter, items: GrammarNode
    ) raises:
        for item in items.args:
            self.generate_item(fmt, item[])
            self.level += 1

    fn generate_action(
        inout self,
        inout fmt: Formatter,
        action: GrammarNode,
        items: GrammarNode,
    ) raises:
        if not action.args:  # '{' item '}'
            self.generate_target_atoms(fmt, action.text, items)
            write_to(fmt, "\n")
            return

        var op = action.args[0].text
        write_to(fmt, "Arc(NodeData(Kind.", op, ", ")
        var target_atoms = action.text  # It is just a string
        self.generate_target_atoms(fmt, target_atoms, items)
        write_to(fmt, "))\n")

    fn generate_target_atoms(
        inout self,
        inout fmt: Formatter,
        target_atoms: String,
        items: GrammarNode,
    ) raises:
        var re = Python.import_module("re2")
        var res = target_atoms[1:-1] if target_atoms[0] == "(" and target_atoms[
            -1
        ] == ")" else target_atoms
        # 1. rewrite squoted string to the corresponding op name
        for op in self.OP_NAMES.keys():
            res = res.replace(
                String.format_sequence("'", op[], "'"),
                self.OP_NAMES.get(op[]).value(),
            )  # 2. rewrite the use of variables with postfix '.take()' or '.value()[]'
        for item in items.args:
            var variable_name = self.get_variable_name(item[])
            res = re.sub(
                "\\b" + variable_name + "\\b",
                variable_name + str("_") + ".take()",
                res,
            )
            res = str(res.replace(".take().", ".take()[]."))
        write_to(fmt, res)

    fn generate_item(
        inout self, inout fmt: Formatter, item: GrammarNode
    ) raises:
        var atom = item.args[0]
        var atom_name = atom.text
        var variable_name = self.get_variable_name(item, str("_"))
        if self.level == 3:
            if variable_name in self.top_level_variables:
                write_to(fmt, self.indent(), variable_name, " = self.")
            else:
                write_to(fmt, self.indent(), "var ", variable_name, " = self.")
                self.top_level_variables.append(variable_name)
        else:
            write_to(fmt, self.indent(), "var ", variable_name, " = self.")
        if atom_name.as_bytes()[0] == 39 or atom_name == atom_name.upper():
            write_to(fmt, '_expect["', atom_name.strip("'"), '"]()\n')
        else:
            write_to(fmt, atom_name, "()\n")
        write_to(fmt, self.indent(), "if ", variable_name, ":\n")
        return

    fn is_left_recursive(self, rule: GrammarNode) -> Bool:
        # Only check direct left recursion
        var rhs = rule.args[0]
        for alt in rhs.args:
            var items = alt[].args[0]
            var first_item = items.args[0]
            var atom = first_item.args[0]
            if atom.text == rule.text:
                return True
        return False
