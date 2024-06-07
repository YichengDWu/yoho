from .tokenizer import Kind, K, Token, Tokenizer
from .node import NodeData, Node
from collections.dict import KeyElement


# Grammar
# Note it right-associative for now
# expr: term '+' expr | term '-' expr | term
# term: atom '*' term | atom '/' term | atom
# atom: NAME | NUMBER | '(' expr ')'


@value
struct Parser:
    var tokenizer: Tokenizer

    fn __init__(inout self, text: String):
        self.tokenizer = Tokenizer(text)

    fn __init__(inout self, owned tokenizer: Tokenizer):
        self.tokenizer = tokenizer^

    @always_inline
    fn mark(self) -> Int:
        return self.tokenizer.mark()

    @always_inline
    fn reset(inout self, mark: Int):
        self.tokenizer.reset(mark)

    fn expect[arg: StringLiteral](inout self) raises -> Optional[Node]:
        var token = self.tokenizer.peek()
        if token.text == arg:
            return Node(self.tokenizer.bump())
        elif K[arg]() and token.kind == K[arg]().value():
            return Node(self.tokenizer.bump())
        return None

    fn expr(inout self: Parser) raises -> Optional[Node]:
        # expr: term '+' expr {Node(BinOp, atom, plus, term)}
        #     | term '-' expr {Node(BinOp, atom, minus, term)}
        #     | term
        var mark = self.mark()

        var term = self.term()
        if term:
            var plus = self.expect["+"]()
            if plus:
                var expr = self.expr()
                if expr:
                    return Arc(
                        NodeData(
                            Kind.BinOp, term.take(), plus.take(), expr.take()
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
                            Kind.BinOp, term1.take(), minus.take(), expr1.take()
                        )
                    )
        self.reset(mark)

        var term2 = self.term()
        if term2:
            return term2
        self.reset(mark)
        return None

    fn term(inout self: Parser) raises -> Optional[Node]:
        # term: atom `*` term {Node(BinOp, atom, star, term)}
        #     | atom `/` term {Node(BinOp, atom, slash, term)}
        #     | atom
        var mark = self.mark()
        var atom = self.atom()
        if atom:
            var star = self.expect["*"]()
            if star:
                var term = self.term()
                if term:
                    return Arc(
                        NodeData(
                            Kind.BinOp, atom.take(), star.take(), term.take()
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
                            Kind.BinOp, atom1.take(), slash.take(), term1.take()
                        )
                    )
        self.reset(mark)

        var atom2 = self.atom()
        if atom2:
            return atom2
        self.reset(mark)

        return None

    fn atom(inout self: Parser) raises -> Optional[Node]:
        # atom: NUMBER
        #     | '(' expr ')' {expr}
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
