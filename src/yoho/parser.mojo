# This file is generated from the following grammar:
# expr:
#     | expr '+' term { BinOp(expr, '+', term) }
#     | expr '-' term { BinOp(expr, '-', term) }
#     | term
#
# term:
#     | term '*' atom { BinOp(term, '*', atom) }
#     | term '/' atom { BinOp(term, '/', atom) }
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
        return self.expr()

    fn expr(inout self: Parser) raises -> Optional[Node]:
        fn _expr(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            if True:
                var expr = self.expr()
                if expr:
                    var _plus = self._expect["+"]()
                    if _plus:
                        var term = self.term()
                        if term:
                            return Arc(
                                NodeData(
                                    Kind.BinOp,
                                    expr.take(),
                                    _plus.take(),
                                    term.take(),
                                )
                            )
            self._reset(_mark)

            if True:
                var expr = self.expr()
                if expr:
                    var _minus = self._expect["-"]()
                    if _minus:
                        var term = self.term()
                        if term:
                            return Arc(
                                NodeData(
                                    Kind.BinOp,
                                    expr.take(),
                                    _minus.take(),
                                    term.take(),
                                )
                            )
            self._reset(_mark)

            if True:
                var term = self.term()
                if term:
                    return term.take()
            self._reset(_mark)

            return None

        return memoize_left_rec["_expr", _expr](self)

    fn term(inout self: Parser) raises -> Optional[Node]:
        fn _term(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            if True:
                var term = self.term()
                if term:
                    var _star = self._expect["*"]()
                    if _star:
                        var atom = self.atom()
                        if atom:
                            return Arc(
                                NodeData(
                                    Kind.BinOp,
                                    term.take(),
                                    _star.take(),
                                    atom.take(),
                                )
                            )
            self._reset(_mark)

            if True:
                var term = self.term()
                if term:
                    var _slash = self._expect["/"]()
                    if _slash:
                        var atom = self.atom()
                        if atom:
                            return Arc(
                                NodeData(
                                    Kind.BinOp,
                                    term.take(),
                                    _slash.take(),
                                    atom.take(),
                                )
                            )
            self._reset(_mark)

            if True:
                var atom = self.atom()
                if atom:
                    return atom.take()
            self._reset(_mark)

            return None

        return memoize_left_rec["_term", _term](self)

    fn atom(inout self: Parser) raises -> Optional[Node]:
        fn _atom(inout self: Parser) raises -> Optional[Node]:
            var _mark = self._mark()

            if True:
                var name = self._expect["NAME"]()
                if name:
                    return name.take()
            self._reset(_mark)

            if True:
                var number = self._expect["NUMBER"]()
                if number:
                    return number.take()
            self._reset(_mark)

            if True:
                var _lpar = self._expect["("]()
                if _lpar:
                    var expr = self.expr()
                    if expr:
                        var _rpar = self._expect[")"]()
                        if _rpar:
                            return expr.take()
            self._reset(_mark)

            return None

        return memoize["_atom", _atom](self)
