# This file is generated from the following grammar:
# program: statements ENDMARKER { statements }
#
# statements:
#     | statement NL* statements { Block(List(statement) + statements.args) }
#     | statement NL* { Block(List(statement)) }
#
# statement:
#     | 'if' test=expr ':' NEWLINE INDENT body=statements DEDENT 'else' ':' NEWLINE INDENT orelse=statements DEDENT { If(test, body, orelse) }
#     | 'if' test=expr ':' NEWLINE INDENT body=statements DEDENT { If(test, body) }
#     | 'return' expr NEWLINE { Return(expr) }
#     | expr NEWLINE { expr }
#
# expr: assign
#
# assign:
#     | NAME '=' assign { Assign(name, assign) }
#     | equality
#
# equality:
#     | equality '==' relational { Compare(equality, '==', relational) }
#     | equality '!=' relational { Compare(equality, '!=', relational) }
#     | relational
#
# relational:
#     | relational '<' add { Compare(relational, '<', add) }
#     | relational '<=' add { Compare(relational, '<=', add) }
#     | relational '>' add { Compare(relational, '>', add) }
#     | relational '>=' add { Compare(relational, '>=', add) }
#     | add
#
# add:
#     | add '+' term { BinOp(add, '+', term) }
#     | add '-' term { BinOp(add, '-', term) }
#     | term
#
# term:
#     | term '*' unary { BinOp(term, '*', unary) }
#     | term '/' unary { BinOp(term, '/', unary) }
#     | unary
#
# unary:
#     | '+' unary { UnaryOp('+', unary) }
#     | '-' unary { UnaryOp('-', unary) }
#     | atom
#
# atom:
#     | NAME
#     | NUMBER
#     | '(' expr ')' { expr }
#

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

    @always_inline
    fn parse(inout self: Parser) raises -> Optional[Node]:
        return self.program()

    fn program(inout self: Parser) raises -> Optional[Node]:
        fn _program(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var statements_ = self.statements()
            if statements_:
                var endmarker_ = self._expect["ENDMARKER"]()
                if endmarker_:
                    return statements_.take()
            self._reset(_mark)

            return None

        return memoize["_program", _program](self)

    fn statements(inout self: Parser) raises -> Optional[Node]:
        fn _statements(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var statement_ = self.statement()
            if statement_:
                var nl_ = Optional(List[Node]())
                var nl__elem = self._expect["NL"]()
                while nl__elem:
                    nl_.value().append(nl__elem.value())
                    nl__elem = self._expect["NL"]()
                var statements_ = self.statements()
                if statements_:
                    return Arc(
                        NodeData(
                            Kind.Block,
                            List(statement_.take()) + statements_.take()[].args,
                        )
                    )
            self._reset(_mark)

            statement_ = self.statement()
            if statement_:
                var nl_ = Optional(List[Node]())
                var nl__elem = self._expect["NL"]()
                while nl__elem:
                    nl_.value().append(nl__elem.value())
                    nl__elem = self._expect["NL"]()
                return Arc(NodeData(Kind.Block, List(statement_.take())))
            self._reset(_mark)

            return None

        return memoize["_statements", _statements](self)

    fn statement(inout self: Parser) raises -> Optional[Node]:
        fn _statement(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var if_ = self._expect["if"]()
            if if_:
                var test_ = self.expr()
                if test_:
                    var colon_ = self._expect[":"]()
                    if colon_:
                        var newline_ = self._expect["NEWLINE"]()
                        if newline_:
                            var indent_ = self._expect["INDENT"]()
                            if indent_:
                                var body_ = self.statements()
                                if body_:
                                    var dedent_ = self._expect["DEDENT"]()
                                    if dedent_:
                                        var else_ = self._expect["else"]()
                                        if else_:
                                            var colon_ = self._expect[":"]()
                                            if colon_:
                                                var newline_ = self._expect[
                                                    "NEWLINE"
                                                ]()
                                                if newline_:
                                                    var indent_ = self._expect[
                                                        "INDENT"
                                                    ]()
                                                    if indent_:
                                                        var orelse_ = self.statements()
                                                        if orelse_:
                                                            var dedent_ = self._expect[
                                                                "DEDENT"
                                                            ]()
                                                            if dedent_:
                                                                return Arc(
                                                                    NodeData(
                                                                        Kind.If,
                                                                        test_.take(),
                                                                        body_.take(),
                                                                        orelse_.take(),
                                                                    )
                                                                )
            self._reset(_mark)

            if_ = self._expect["if"]()
            if if_:
                var test_ = self.expr()
                if test_:
                    var colon_ = self._expect[":"]()
                    if colon_:
                        var newline_ = self._expect["NEWLINE"]()
                        if newline_:
                            var indent_ = self._expect["INDENT"]()
                            if indent_:
                                var body_ = self.statements()
                                if body_:
                                    var dedent_ = self._expect["DEDENT"]()
                                    if dedent_:
                                        return Arc(
                                            NodeData(
                                                Kind.If,
                                                test_.take(),
                                                body_.take(),
                                            )
                                        )
            self._reset(_mark)

            var return_ = self._expect["return"]()
            if return_:
                var expr_ = self.expr()
                if expr_:
                    var newline_ = self._expect["NEWLINE"]()
                    if newline_:
                        return Arc(NodeData(Kind.Return, expr_.take()))
            self._reset(_mark)

            var expr_ = self.expr()
            if expr_:
                var newline_ = self._expect["NEWLINE"]()
                if newline_:
                    return expr_.take()
            self._reset(_mark)

            return None

        return memoize["_statement", _statement](self)

    fn expr(inout self: Parser) raises -> Optional[Node]:
        fn _expr(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var assign_ = self.assign()
            if assign_:
                return assign_.take()
            self._reset(_mark)

            return None

        return memoize["_expr", _expr](self)

    fn assign(inout self: Parser) raises -> Optional[Node]:
        fn _assign(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var name_ = self._expect["NAME"]()
            if name_:
                var equal_ = self._expect["="]()
                if equal_:
                    var assign_ = self.assign()
                    if assign_:
                        return Arc(
                            NodeData(Kind.Assign, name_.take(), assign_.take())
                        )
            self._reset(_mark)

            var equality_ = self.equality()
            if equality_:
                return equality_.take()
            self._reset(_mark)

            return None

        return memoize["_assign", _assign](self)

    fn equality(inout self: Parser) raises -> Optional[Node]:
        fn _equality(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var equality_ = self.equality()
            if equality_:
                var eqeq_ = self._expect["=="]()
                if eqeq_:
                    var relational_ = self.relational()
                    if relational_:
                        return Arc(
                            NodeData(
                                Kind.Compare,
                                equality_.take(),
                                eqeq_.take(),
                                relational_.take(),
                            )
                        )
            self._reset(_mark)

            equality_ = self.equality()
            if equality_:
                var neq_ = self._expect["!="]()
                if neq_:
                    var relational_ = self.relational()
                    if relational_:
                        return Arc(
                            NodeData(
                                Kind.Compare,
                                equality_.take(),
                                neq_.take(),
                                relational_.take(),
                            )
                        )
            self._reset(_mark)

            var relational_ = self.relational()
            if relational_:
                return relational_.take()
            self._reset(_mark)

            return None

        return memoize_left_rec["_equality", _equality](self)

    fn relational(inout self: Parser) raises -> Optional[Node]:
        fn _relational(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var relational_ = self.relational()
            if relational_:
                var less_ = self._expect["<"]()
                if less_:
                    var add_ = self.add()
                    if add_:
                        return Arc(
                            NodeData(
                                Kind.Compare,
                                relational_.take(),
                                less_.take(),
                                add_.take(),
                            )
                        )
            self._reset(_mark)

            relational_ = self.relational()
            if relational_:
                var leq_ = self._expect["<="]()
                if leq_:
                    var add_ = self.add()
                    if add_:
                        return Arc(
                            NodeData(
                                Kind.Compare,
                                relational_.take(),
                                leq_.take(),
                                add_.take(),
                            )
                        )
            self._reset(_mark)

            relational_ = self.relational()
            if relational_:
                var greater_ = self._expect[">"]()
                if greater_:
                    var add_ = self.add()
                    if add_:
                        return Arc(
                            NodeData(
                                Kind.Compare,
                                relational_.take(),
                                greater_.take(),
                                add_.take(),
                            )
                        )
            self._reset(_mark)

            relational_ = self.relational()
            if relational_:
                var geq_ = self._expect[">="]()
                if geq_:
                    var add_ = self.add()
                    if add_:
                        return Arc(
                            NodeData(
                                Kind.Compare,
                                relational_.take(),
                                geq_.take(),
                                add_.take(),
                            )
                        )
            self._reset(_mark)

            var add_ = self.add()
            if add_:
                return add_.take()
            self._reset(_mark)

            return None

        return memoize_left_rec["_relational", _relational](self)

    fn add(inout self: Parser) raises -> Optional[Node]:
        fn _add(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var add_ = self.add()
            if add_:
                var plus_ = self._expect["+"]()
                if plus_:
                    var term_ = self.term()
                    if term_:
                        return Arc(
                            NodeData(
                                Kind.BinOp,
                                add_.take(),
                                plus_.take(),
                                term_.take(),
                            )
                        )
            self._reset(_mark)

            add_ = self.add()
            if add_:
                var minus_ = self._expect["-"]()
                if minus_:
                    var term_ = self.term()
                    if term_:
                        return Arc(
                            NodeData(
                                Kind.BinOp,
                                add_.take(),
                                minus_.take(),
                                term_.take(),
                            )
                        )
            self._reset(_mark)

            var term_ = self.term()
            if term_:
                return term_.take()
            self._reset(_mark)

            return None

        return memoize_left_rec["_add", _add](self)

    fn term(inout self: Parser) raises -> Optional[Node]:
        fn _term(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var term_ = self.term()
            if term_:
                var star_ = self._expect["*"]()
                if star_:
                    var unary_ = self.unary()
                    if unary_:
                        return Arc(
                            NodeData(
                                Kind.BinOp,
                                term_.take(),
                                star_.take(),
                                unary_.take(),
                            )
                        )
            self._reset(_mark)

            term_ = self.term()
            if term_:
                var slash_ = self._expect["/"]()
                if slash_:
                    var unary_ = self.unary()
                    if unary_:
                        return Arc(
                            NodeData(
                                Kind.BinOp,
                                term_.take(),
                                slash_.take(),
                                unary_.take(),
                            )
                        )
            self._reset(_mark)

            var unary_ = self.unary()
            if unary_:
                return unary_.take()
            self._reset(_mark)

            return None

        return memoize_left_rec["_term", _term](self)

    fn unary(inout self: Parser) raises -> Optional[Node]:
        fn _unary(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var plus_ = self._expect["+"]()
            if plus_:
                var unary_ = self.unary()
                if unary_:
                    return Arc(
                        NodeData(Kind.UnaryOp, plus_.take(), unary_.take())
                    )
            self._reset(_mark)

            var minus_ = self._expect["-"]()
            if minus_:
                var unary_ = self.unary()
                if unary_:
                    return Arc(
                        NodeData(Kind.UnaryOp, minus_.take(), unary_.take())
                    )
            self._reset(_mark)

            var atom_ = self.atom()
            if atom_:
                return atom_.take()
            self._reset(_mark)

            return None

        return memoize["_unary", _unary](self)

    fn atom(inout self: Parser) raises -> Optional[Node]:
        fn _atom(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            var name_ = self._expect["NAME"]()
            if name_:
                return name_.take()
            self._reset(_mark)

            var number_ = self._expect["NUMBER"]()
            if number_:
                return number_.take()
            self._reset(_mark)

            var lpar_ = self._expect["("]()
            if lpar_:
                var expr_ = self.expr()
                if expr_:
                    var rpar_ = self._expect[")"]()
                    if rpar_:
                        return expr_.take()
            self._reset(_mark)

            return None

        return memoize["_atom", _atom](self)
