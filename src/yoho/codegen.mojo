from .node import Node
from .tokenizer import Kind


struct CodeGen:
    var reg_counter: Int
    var reg_pool: List[String]
    var symbol_table: Dict[String, Int]
    var stack_size: Int

    fn __init__(inout self):
        self.reg_counter = 0
        self.reg_pool = List[String]()
        self.symbol_table = Dict[String, Int]()
        self.stack_size = 0

    @staticmethod
    fn align_to[align: Int = 16](n: Int) -> Int:
        return (n + align - 1) & ~(align - 1)

    fn get_next_reg(inout self) -> String:
        if len(self.reg_pool) > 0:
            return self.reg_pool.pop()
        else:
            var reg = "t" + str(self.reg_counter)
            self.reg_counter += 1
            return reg

    fn release_reg(inout self, reg: String):
        if reg:
            self.reg_pool.append(reg)

    fn build_stack_frame(inout self, node: Node):
        var _node = node
        var kind = _node[].kind

        if kind == Kind.NUMBER or kind == Kind.NAME:
            return

        if kind == Kind.Assign:
            var variable = _node[].args[0]
            var value = _node[].args[1]
            var variable_name = variable[].text
            if variable_name not in self.symbol_table:
                self.stack_size += 8
                self.symbol_table[variable_name] = self.stack_size
            self.build_stack_frame(value)
        else:
            for arg in _node[].args:
                self.build_stack_frame(arg[])

    fn gen(inout self, inout fmt: Formatter, inout node: Node) raises:
        self.build_stack_frame(node)
        var aligned_stack_size = self.align_to(self.stack_size)
        if self.stack_size:
            write_to(fmt, "    add sp, sp, -", aligned_stack_size, "\n")
        var reg = self._gen(fmt, node)
        if self.stack_size:
            write_to(fmt, "    add sp, sp, ", aligned_stack_size, "\n")
        write_to(fmt, "    mv a0, ", reg, "\n")
        write_to(fmt, "    ret\n")

    fn _gen(
        inout self, inout fmt: Formatter, inout node: Node
    ) raises -> String:
        var _node = node
        var kind = _node[].kind

        if kind == Kind.Block:
            var reg = String()
            for statement in _node[].args:
                self.release_reg(reg)
                reg = self._gen(fmt, statement[])
            return reg

        elif kind == Kind.BinOp:
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

        elif kind == Kind.UnaryOp:
            var op = _node[].args[0]
            var reg = self._gen(fmt, _node[].args[1])
            if op[].text == "+":
                return reg
            elif op[].text == "-":
                write_to(fmt, "    neg ", reg, ", ", reg, "\n")
                return reg
            else:
                raise Error("unknown unary operator")

        elif kind == Kind.Compare:
            var left_ref = self._gen(fmt, _node[].args[0])
            var right_ref = self._gen(fmt, _node[].args[2])
            var op = _node[].args[1]
            if op[].text == "<":
                write_to(
                    fmt,
                    "    slt ",
                    left_ref,
                    ", ",
                    left_ref,
                    ", ",
                    right_ref,
                    "\n",
                )
            elif op[].text == ">":
                write_to(
                    fmt,
                    "    slt ",
                    left_ref,
                    ", ",
                    right_ref,
                    ", ",
                    left_ref,
                    "\n",
                )
            elif op[].text == "<=":
                write_to(
                    fmt,
                    "    slt ",
                    left_ref,
                    ", ",
                    right_ref,
                    ", ",
                    left_ref,
                    "\n",
                )
                write_to(fmt, "    seqz ", left_ref, ", ", left_ref, "\n")
            elif op[].text == ">=":
                write_to(
                    fmt,
                    "    slt ",
                    left_ref,
                    ", ",
                    left_ref,
                    ", ",
                    right_ref,
                    "\n",
                )
                write_to(fmt, "    seqz ", left_ref, ", ", left_ref, "\n")
            elif op[].text == "==":
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
                write_to(fmt, "    seqz ", left_ref, ", ", left_ref, "\n")
            elif op[].text == "!=":
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
                write_to(fmt, "    snez ", left_ref, ", ", left_ref, "\n")
            self.release_reg(right_ref)
            return left_ref

        elif kind == Kind.UnaryOp:
            var op = _node[].args[0]
            var reg = self._gen(fmt, _node[].args[1])
            if op[].text == "+":
                return reg
            elif op[].text == "-":
                write_to(fmt, "    neg ", reg, ", ", reg, "\n")
                return reg
            else:
                raise Error("unknown unary operator")

        elif kind == Kind.Assign:
            var variable = _node[].args[0]
            var variable_name = variable[].text
            var value = _node[].args[1]
            var reg = self._gen(fmt, value)
            var offset = self.stack_size - self.symbol_table[variable_name]
            write_to(fmt, "    sd ", reg, ", ", offset, "(sp)\n")
            return reg

        elif kind == Kind.NAME:
            var var_name = _node[].text
            var reg = self.get_next_reg()
            var offset = self.stack_size - self.symbol_table[var_name]
            write_to(fmt, "    ld ", reg, ", ", offset, "(sp)\n")
            return reg

        elif kind == Kind.NUMBER:
            var reg = self.get_next_reg()
            write_to(fmt, "    li ", reg, ", ", _node[].text, "\n")
            return reg
        else:
            raise Error("unknown node kind")
