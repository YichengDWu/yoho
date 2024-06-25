from .node import Node
from .tokenizer import Kind


@value
struct Function:
    var name: String
    var return_type: String
    var symbol_table: Dict[String, Int]  # variable name -> stack offset
    var stack_size: Int
    var reg_pool: List[String]
    var reg_counter: Int
    var branch_counter: Int

    fn __init__(inout self, name: String, return_type: String):
        self.name = name
        self.return_type = return_type
        self.symbol_table = Dict[String, Int]()
        self.stack_size = 0
        self.reg_pool = List[String]()
        self.reg_counter = 0
        self.branch_counter = 0

    fn __init__(inout self, node: Node):
        var _node = node

        var name = _node[].text
        var return_type = "int"  # for now only support int
        self = Function(name, return_type)

        for arg in _node[].args:
            self.build_stack_frame(arg[])

        for e in self.symbol_table.items():
            self.symbol_table[e[].key] = self.stack_size - e[].value
        self.align_to[16]()

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

        if kind == Kind.Declare:
            var variable = _node[].args[0]
            var variable_name = variable[].text
            if variable_name not in self.symbol_table:
                self.stack_size += 8
                self.symbol_table[variable_name] = self.stack_size

        if _node[].args:
            for arg in _node[].args:
                self.build_stack_frame(arg[])

    fn align_to[align: Int = 16](inout self):
        self.stack_size = (self.stack_size + align - 1) & ~(align - 1)

    fn build(inout self, inout fmt: Formatter, node: Node) raises:
        var _node = node

        write_to(fmt, self.name, ":\n")
        if self.stack_size:
            write_to(fmt, "    add sp, sp, -", self.stack_size, "\n")

        for arg in _node[].args:
            var reg = self._build(fmt, arg[])
            self.release_reg(reg)

        write_to(fmt, ".L.return:\n")
        if self.stack_size:
            write_to(fmt, "    add sp, sp, ", self.stack_size, "\n")
        write_to(fmt, "    ret\n")

    fn _build(inout self, inout fmt: Formatter, node: Node) raises -> String:
        var _node = node
        var kind = _node[].kind

        if kind == Kind.BinOp:
            var left_ref = self._build(fmt, _node[].args[0])
            var right_ref = self._build(fmt, _node[].args[2])
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
            var reg = self._build(fmt, _node[].args[1])
            if op[].text == "+":
                return reg
            elif op[].text == "-":
                write_to(fmt, "    neg ", reg, ", ", reg, "\n")
                return reg
            else:
                raise Error("unknown unary operator")

        elif kind == Kind.Compare:
            var left_ref = self._build(fmt, _node[].args[0])
            var right_ref = self._build(fmt, _node[].args[2])
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
            var reg = self._build(fmt, _node[].args[1])
            if op[].text == "+":
                return reg
            elif op[].text == "-":
                write_to(fmt, "    neg ", reg, ", ", reg, "\n")
                return reg
            else:
                raise Error("unknown unary operator")

        elif kind == Kind.Declare or kind == Kind.Assign:
            var variable = _node[].args[0]
            var variable_name = variable[].text
            if variable_name not in self.symbol_table:
                raise Error(
                    "use of unkonwn declaration '" + variable_name + "'"
                )
            var value = _node[].args[1]
            var reg = self._build(fmt, value)
            write_to(
                fmt,
                "    sd ",
                reg,
                ", ",
                self.symbol_table[variable_name],
                "(sp)\n",
            )
            return reg

        elif kind == Kind.Return:
            if _node[].args:
                var reg = self._build(fmt, _node[].args[0])
                write_to(fmt, "    mv a0, ", reg, "\n")
                write_to(fmt, "    j .L.return\n")
                return reg
            else:
                raise Error("return statement without value")

        elif kind == Kind.If:
            self.branch_counter += 1
            var counter = self.branch_counter
            var cond = _node[].args[0]
            var body = _node[].args[1]

            var cond_reg = self._build(fmt, cond)
            write_to(
                fmt,
                "    beqz ",
                cond_reg,
                ", .L.else.",
                counter,
                "\n",
            )
            self.release_reg(cond_reg)

            var body_reg = self._build(fmt, body)
            if len(_node[].args) == 3:
                write_to(fmt, "    j .L.end.", counter, "\n")

            write_to(fmt, ".L.else.", counter, ":\n")
            if len(_node[].args) == 3:
                var else_reg = self._build(fmt, _node[].args[2])
                write_to(fmt, ".L.end.", counter, ":\n")
                self.release_reg(body_reg)
                return else_reg
            return body_reg

        elif kind == Kind.While:
            self.branch_counter += 1
            var counter = self.branch_counter
            var cond = _node[].args[0]
            var body = _node[].args[1]

            write_to(fmt, ".L.loop.", counter, ":\n")
            var cond_reg = self._build(fmt, cond)
            write_to(
                fmt,
                "    beqz ",
                cond_reg,
                ", .L.exit.",
                counter,
                "\n",
            )
            self.release_reg(cond_reg)

            var body_reg = self._build(fmt, body)
            write_to(fmt, "    j .L.loop.", counter, "\n")
            write_to(fmt, ".L.exit.", counter, ":\n")
            return body_reg

        elif kind == Kind.NAME:
            var variable_name = _node[].text
            var reg = self.get_next_reg()
            write_to(
                fmt,
                "    ld ",
                reg,
                ", ",
                self.symbol_table[variable_name],
                "(sp)\n",
            )
            return reg

        elif kind == Kind.NUMBER:
            var reg = self.get_next_reg()
            write_to(fmt, "    li ", reg, ", ", _node[].text, "\n")
            return reg
        else:
            raise Error("unknown node kind")


@value
struct Module:
    fn build(self, inout fmt: Formatter, node: Node) raises:
        var _node = node
        for arg in _node[].args:
            var _arg = arg[]
            if _arg[].kind == Kind.FunctionDef:
                var function = Function(arg[])
                function.build(fmt, arg[])


@value
struct CodeGen:
    fn build(self, inout fmt: Formatter, node: Node) raises:
        var _node = node

        write_to(fmt, ".global main\n")
        if _node[].kind == Kind.Module:
            var module = Module()
            module.build(fmt, _node)
