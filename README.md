# Yoho 🔥

Yoho 🔥 is a toy compiler crafted in Mojo 🔥 and designed to generate RISC-V assembly language.

# Status

This project is currently under active development. 
Please refer to `test.sh` for example programs that the current version of the compiler supports.

# Overview

## Tokenizer

The tokenizer for this compiler is implemented quite manually. It calls the [`re2`](https://github.com/google/re2) Python library
for regular expression operations at the low level.

## Parser

The parser is based on Parsing Expression Grammar (PEG). It is capable of automatically generating parsers from .gram files. Below is the meta-grammar used for defining the grammar:

```c
start: grammar ENDMARKER { grammar }

grammar: rules=rule+ { Grammar(rules) }

rule: 
    | NAME ':' NEWLINE INDENT rhs NL DEDENT { Rule(name.text, rhs)}
    | NAME ':' rhs NL { Rule(name.text, rhs)}

rhs: 
    | '|' alt NEWLINE rhs { Rhs(List(alt) + rhs.args)}
    | '|' alt NEWLINE { Rhs(List(alt)) }
    | alt NEWLINE { Rhs(List(alt)) }

alt: 
    | items action { Alt(items, action) } 
    | items { Alt(items) }

items: items=named_item+ { Items(items) }

named_item: 
    | NAME '=' item { NamedItem(item, name.text)}
    | item { NamedItem(item) }
    
item: 
    | atom '*' { Repeat0(atom) }
    | atom '+' { Repeat1(atom) }
    | sep=atom '.' node=atom '+' { Gather(sep.text, node) }
    | atom 
    
atom: 
    | '(' items ')' { Group(items.args) }
    | NAME { Atom(name.text) } 
    | STRING { Atom(string.text) }
    
action: '{' target '}' { target }

target: 
    | NAME target_atoms { Action(target_atoms, name)}
    | target_atom { Action(target_atom) }

target_atoms: 
    | target_atom target_atoms { String(target_atom + ' ' + target_atoms) }
    | target_atom 

target_atom:
    | NAME { String(name.text) }
    | NUMBER { String(number.text) }
    | ',' { String(', ') }
    | '+' { String(' + ') }
    | '(' { String('(') }
    | ')' { String(')') }
    | '.' { String('.')}

```
This meta-grammar provides a flexible and powerful way to define and generate the parser.

The parse tree can be nicely printed out:
```python
      0:12      ┃            ┃  BinOp                             
       0:1      ┃     '1'    ┃    NUMBER                          ✔
       1:2      ┃     '-'    ┃    MINUS                           ✔
      3:12      ┃            ┃    BinOp                           
       3:8      ┃            ┃      BinOp                         
       3:4      ┃     '2'    ┃        NUMBER                      ✔
       4:5      ┃     '+'    ┃        PLUS                        ✔
       5:8      ┃            ┃        BinOp                       
       5:6      ┃     '3'    ┃          NUMBER                    ✔
       6:7      ┃     '*'    ┃          STAR                      ✔
       7:8      ┃     '2'    ┃          NUMBER                    ✔
       8:9      ┃     '-'    ┃      MINUS                         ✔
      9:12      ┃            ┃      BinOp                         
      9:10      ┃     '3'    ┃        NUMBER                      ✔
     10:11      ┃     '/'    ┃        SLASH                       ✔
     11:12      ┃     '2'    ┃        NUMBER                      ✔
```

# CodeGen

The code generator simply reads in an ast and emit RISC-V assembly. 
Yes some of the source code might look silly to you and it was somewhat intentional. Simplicity and readability for first-time readers is my top priority. There is no IR or LLVM/MLIR in yoho.


# References

This compiler was developed with inspiration and reference from the following projects:

- [chibicc](https://github.com/rui314/chibicc): A small C compiler.
- [pegen](https://github.com/we-like-parsers/pegen): A PEG-based parser generator.
    
# Installation

## Prerequisites

Ensure you have the following installed:

- Mojo Nightly Version. Visit the [Mojo Lang website](https://www.modular.com/max/mojo) and follow the instructions to download and install the nightly version of Mojo.
- RISC-V Toolchain. Visit [this guide](https://github.com/johnwinans/riscv-toolchain-install-guide) to install RISC-V toolchain.

## Steps to Install the Compiler

1. Clone the Repository.
2. Build the Compiler:
```shell
make yoho
```

3. Run test:
```shell
make test
```
4. Clean Up:
```shell
make clean
```

## Example Output

Here is an example of the output RISC-V assembly code of '1*2+ 4*5-(4-3>2)':

```assembly
.global  main
main:
    li t0, 1
    li t1, 2
    mul t0, t0, t1
    li t1, 4
    li t2, 5
    mul t1, t1, t2
    add t0, t0, t1
    li t1, 4
    li t2, 3
    sub t1, t1, t2
    li t2, 2
    slt t1, t2, t1
    sub t0, t0, t1
    mv a0, t0
    ret
```

Please refer to `test.sh` for more example programs.

# Contributing

Inspired by [chibicc](https://github.com/rui314/chibicc)'s approach to maintaining a clean commit history, we adopt a similar style for handling contributions.

> When a bug is found in this compiler, I trace back to the original commit that introduced the bug and rewrite the commit history as if the bug never existed. This method, while unconventional, ensures that each commit remains bug-free, which is crucial for the integrity of the project.

The repository is committed to "every commit is bug free".  If you discover a bug and submit an issue, I will apply the necessary changes to the relevant previous commits by rewriting the history. 

# License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/YichengDWu/yoho/blob/main/LICENSE) file for details.
