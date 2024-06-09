from .grammar import (
    GrammarNode,
    Grammar,
    Rule,
    Rhs,
    Alt,
    Items,
    NamedItem,
    Repeat0,
    Repeat1,
    Gather,
    Group,
    Atom,
    Action,
)
from yoho.tokenizer import K, Tokenizer


@value
struct GrammarParser:
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

    fn expect[arg: StringLiteral](inout self) raises -> Optional[GrammarNode]:
        var token = self.tokenizer.peek()
        if token.text == arg:
            return Atom(self.tokenizer.bump().text)
        elif K[arg]() and token.kind == K[arg]().value():
            return Atom(self.tokenizer.bump().text)
        return None

    fn start(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()
        var grammar = self.grammar()
        if grammar:
            var endmarker = self.expect["ENDMARKER"]()
            if endmarker:
                return grammar
        self.reset(pos)
        return None

    fn grammar(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()
        var rule = self.rule()
        if rule:
            var rules = List[GrammarNode](rule.take())
            var new_rule = self.rule()
            while new_rule:
                rules.append(new_rule.take())
                new_rule = self.rule()
            return Grammar(rules)
        self.reset(pos)
        return None

    fn rule(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()

        var name = self.expect["NAME"]()
        if name:
            if (
                self.expect[":"]()
                and self.expect["NEWLINE"]()
                and self.expect["INDENT"]()
            ):
                var rhs = self.rhs()
                if rhs:
                    if self.expect["NL"]() and self.expect["DEDENT"]():
                        return Rule(name.value().text, rhs.take())
        self.reset(pos)

        name = self.expect["NAME"]()
        if name:
            if self.expect[":"]():
                var rhs = self.rhs()
                if rhs:
                    if self.expect["NL"]():
                        return Rule(name.value().text, rhs.take())

        return None

    fn rhs(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()
        if self.expect["|"]():
            var alt = self.alt()
            if self.expect["NEWLINE"]():
                var rhs = self.rhs()
                if rhs:
                    return Rhs(List(alt.take()) + rhs.value().args)
                else:
                    return Rhs(List(alt.take()))
        self.reset(pos)

        var alt = self.alt()
        if self.expect["NEWLINE"]():
            return Rhs(List(alt.take()))
        return None

    fn alt(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()
        var items = self.items()
        if items:
            var action = self.action()
            if action:
                return Alt(items.take(), action.take())
            else:
                return Alt(items.take())
        self.reset(pos)
        return None

    fn items(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()
        var named_item = self.named_item()
        if named_item:
            var named_items = List[GrammarNode](named_item.take())
            var new_named_item = self.named_item()
            while new_named_item:
                named_items.append(new_named_item.take())
                new_named_item = self.named_item()
            return Items(named_items)
        self.reset(pos)
        return None

    fn named_item(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()
        var name = self.expect["NAME"]()
        if name:
            if self.expect["="]():
                var item = self.item()
                if item:
                    return NamedItem(item.take(), name.value().text)
        self.reset(pos)

        var item = self.item()
        if item:
            return NamedItem(item.take())
        self.reset(pos)
        return None

    fn item(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()
        var atom = self.atom()
        if atom:
            if self.expect["*"]():
                return Repeat0(atom.take())
            if self.expect["+"]():
                return Repeat1(atom.take())
            if self.expect["."]():
                var node = self.atom()
                if node:
                    if self.expect["+"]():
                        return Gather(atom.value().text, node.take())
            return atom
        self.reset(pos)
        return None

    fn atom(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()
        var lpar = self.expect["("]()
        if lpar:
            var items = self.items()
            if items:
                var rpar = self.expect[")"]()
                if rpar:
                    return Group(items.value().args)
        self.reset(pos)

        var name = self.expect["NAME"]()
        if name:
            return Atom(name.take().text)
        var string = self.expect["STRING"]()
        if string:
            return Atom(string.take().text)
        self.reset(pos)
        return None

    fn action(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()
        if self.expect["{"]():
            var target = self.target()
            if target:
                if self.expect["}"]():
                    return target
        self.reset(pos)
        return None

    fn target(inout self) raises -> Optional[GrammarNode]:
        var pos = self.mark()
        var name = self.expect["NAME"]()
        if name:
            var target_atoms = self.target_atoms()
            if target_atoms:
                return Action(target_atoms.take(), name.take())
        self.reset(pos)

        var target_atom = self.target_atom()
        if target_atom:
            return Action(target_atom.take())
        self.reset(pos)
        return None

    fn target_atoms(inout self) raises -> Optional[String]:
        var pos = self.mark()
        var target_atom = self.target_atom()
        if target_atom:
            var target_atoms = self.target_atoms()
            if target_atoms:
                return String(target_atom.take() + target_atoms.take())
            return String(target_atom.take())
        self.reset(pos)
        return None

    fn target_atom(inout self) raises -> Optional[String]:
        var pos = self.mark()
        var name = self.expect["NAME"]()
        if name:
            return String(name.take().text)
        self.reset(pos)
        var string = self.expect["STRING"]()
        if string:
            return String(string.take().text)
        self.reset(pos)
        var comma = self.expect[","]()
        if comma:
            return String(", ")
        self.reset(pos)
        var plus = self.expect["+"]()
        if plus:
            return String(" + ")
        self.reset(pos)
        var lpar = self.expect["("]()
        if lpar:
            return String("(")
        self.reset(pos)
        var rpar = self.expect[")"]()
        if rpar:
            return String(")")
        self.reset(pos)
        var dot = self.expect["."]()
        if dot:
            return String(".")
        self.reset(pos)
        return None
