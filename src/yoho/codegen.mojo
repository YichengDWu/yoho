from .node import Node
from .tokenizer import Kind


struct CodeGen:
    var reg_counter: Int
    var reg_pool: List[String]

    fn __init__(inout self):
        self.reg_counter = 0
        self.reg_pool = List[String]()

    fn get_next_reg(inout self) -> String:
        if len(self.reg_pool) > 0:
            return self.reg_pool.pop()
        else:
            var reg = "t" + str(self.reg_counter)
            self.reg_counter += 1
            return reg

    fn release_reg(inout self, reg: String):
        self.reg_pool.append(reg)

    fn gen(inout self, inout fmt: Formatter, inout node: Node) raises:
        var reg = self._gen(fmt, node)
        write_to(fmt, "    mv a0, ", reg, "\n")

    fn _gen(
        inout self, inout fmt: Formatter, inout node: Node
    ) raises -> String:
        var _node = node
        var kind = _node[].kind
        if kind == Kind.BinOp:
            var left_ref = self._gen(fmt, _node[].args[0])
            var right_ref = self._gen(fmt, _node[].args[2])
            var op = _node[].args[1]
            if op[].text == "+":
                write_to(
                    fmt,
                    "    add ",
                    left_ref,
                    ", ",
                    left_ref,
                    ", ",
                    right_ref,
                    "\n",
                )
            elif op[].text == "-":
                write_to(
                    fmt,
                    "    sub ",
                    left_ref,
                    ", ",
                    left_ref,
                    ", ",
                    right_ref,
                    "\n",
                )
            elif op[].text == "*":
                write_to(
                    fmt,
                    "    mul ",
                    left_ref,
                    ", ",
                    left_ref,
                    ", ",
                    right_ref,
                    "\n",
                )
            elif op[].text == "/":
                write_to(
                    fmt,
                    "    div ",
                    left_ref,
                    ", ",
                    left_ref,
                    ", ",
                    right_ref,
                    "\n",
                )
            self.release_reg(right_ref)
            return left_ref

        elif kind == Kind.NUMBER:
            var reg = self.get_next_reg()
            write_to(fmt, "    li ", reg, ", ", _node[].text, "\n")
            return reg
        else:
            raise Error("unknown node kind")
