from sys import argv
from yoho import TokenGenerator


fn main() raises:
    if len(argv()) != 2:
        raise Error("invalid number of arguments")

    var s = argv()[1]
    var tokengen = TokenGenerator(s)
    var token = tokengen.next_token()

    print(".global  main")
    print("main:")
    print("    li a0, ", token.text)

    while True:
        token = tokengen.next_token()
        if token.text == "+":
            print("    addi a0, a0, ", tokengen.next_token().text)
        elif token.text == "-":
            print("    addi a0, a0, ", "-" + tokengen.next_token().text)
        elif token.iseof():
            break
        else:
            raise Error("invalid token")

    print("    ret")
