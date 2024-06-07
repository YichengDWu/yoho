from .tokenizer import Kind, K, Token, Tokenizer
from .node import NodeData, Node
from collections.dict import KeyElement


# Grammar
# Note it right-associative for now
# expr: term '+' expr | term '-' expr | term
# term: atom '*' term | atom '/' term | atom
# atom: NAME | NUMBER | '(' expr ')'


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
    var mark: Int
    var id: StringLiteral  # function + arg

    fn __init__(inout self, mark: Int, id: StringLiteral):
        self.mark = mark
        self.id = id

    fn __hash__(self) -> Int:
        return hash(String.format_sequence(self.mark, ",", self.id))

    fn __eq__(self, other: CacheKey) -> Bool:
        return self.mark == other.mark

    fn __ne__(self, other: CacheKey) -> Bool:
        return not self == other

    fn __repr__(self) -> String:
        return String.format_sequence("(", self.mark, ", ", self.id, ")")


fn memoize[
    id: StringLiteral, unmemoized: fn (inout Parser) raises -> Optional[Node]
](inout self: Parser) raises -> Optional[Node]:
    var mark = self.mark()
    var key = CacheKey(mark, id)
    var value = self.cache.get(key)
    if value:
        var tree = value.value().node
        var endmark = value.value().endmark
        self.reset(endmark)
        return tree

    var tree = unmemoized(self)
    var endmark = self.mark()
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
    fn mark(self) -> Int:
        return self.tokenizer.mark()

    @always_inline
    fn reset(inout self, mark: Int):
        self.tokenizer.reset(mark)

    fn expect[arg: StringLiteral](inout self: Parser) raises -> Optional[Node]:
        fn _expect[
            arg: StringLiteral
        ](inout self: Parser) raises -> Optional[Node]:
            var token = self.tokenizer.peek()
            if token.text == arg:
                return Node(self.tokenizer.bump())
            elif K[arg]() and token.kind == K[arg]().value():
                return Node(self.tokenizer.bump())
            return None

        return memoize[arg, _expect[arg]](self)

    fn expr(inout self: Parser) raises -> Optional[Node]:
        # expr: term '+' expr {Node(BinOp, atom, plus, term)}
        #     | term '-' expr {Node(BinOp, atom, minus, term)}
        #     | term
        fn _expr(inout self: Parser) raises -> Optional[Node]:
            var mark = self.mark()

            var term = self.term()
            if term:
                var plus = self.expect["+"]()
                if plus:
                    var expr = self.expr()
                    if expr:
                        return Arc(
                            NodeData(
                                Kind.BinOp,
                                term.take(),
                                plus.take(),
                                expr.take(),
                            )
                        )

            self.reset(mark)

            var term1 = self.term()
            if term1:
                var minus = self.expect["-"]()
                if minus:
                    var expr1 = self.expr()
                    if expr1:
                        return Arc(
                            NodeData(
                                Kind.BinOp,
                                term1.take(),
                                minus.take(),
                                expr1.take(),
                            )
                        )
            self.reset(mark)

            var term2 = self.term()
            if term2:
                return term2
            self.reset(mark)
            return None

        return memoize["expr", _expr](self)

    fn term(inout self: Parser) raises -> Optional[Node]:
        # term: atom `*` term {Node(BinOp, atom, star, term)}
        #     | atom `/` term {Node(BinOp, atom, slash, term)}
        #     | atom
        fn _term(inout self: Parser) raises -> Optional[Node]:
            var mark = self.mark()
            var atom = self.atom()
            if atom:
                var star = self.expect["*"]()
                if star:
                    var term = self.term()
                    if term:
                        return Arc(
                            NodeData(
                                Kind.BinOp,
                                atom.take(),
                                star.take(),
                                term.take(),
                            )
                        )
            self.reset(mark)

            var atom1 = self.atom()
            if atom1:
                var slash = self.expect["/"]()
                if slash:
                    var term1 = self.term()
                    if term1:
                        return Arc(
                            NodeData(
                                Kind.BinOp,
                                atom1.take(),
                                slash.take(),
                                term1.take(),
                            )
                        )
            self.reset(mark)

            var atom2 = self.atom()
            if atom2:
                return atom2
            self.reset(mark)

            return None

        return memoize["term", _term](self)

    fn atom(inout self: Parser) raises -> Optional[Node]:
        # atom: NUMBER
        #     | '(' expr ')' {expr}
        fn _atom(inout self: Parser) raises -> Optional[Node]:
            var mark = self.mark()

            var number = self.expect["NUMBER"]()
            if number:
                return number.take()
            self.reset(mark)

            if self.expect["("]():
                var expr = self.expr()
                if expr:
                    if self.expect[")"]():
                        return expr
            self.reset(mark)

            return None

        return memoize["atom", _atom](self)