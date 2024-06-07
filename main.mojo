from sys import argv

fn get_token(s: String, inout i: Int) -> String:
    if s[i] == "+":
        i += 1
        return "+"
    elif s[i] == "-":
        i += 1
        return "-"

    var token = String("")
    while i < len(s) and s[i] != " " and s[i] != "+" and s[i] != "-":
        token += s[i]
        i += 1            
    return token


fn main() raises:
    if len(argv()) != 2:
        raise Error("invalid number of arguments")

    var s = argv()[1]
    var i = 0

    print(".global  main")
    print("main:")
    print("    li a0, ", argv()[1])
    print("    ret\n")
    print("    li a0, ", get_token(s, i))

    while i < len(s):
        var token = get_token(s, i)
        if token == "+":
            print("    addi a0, a0, ", get_token(s, i))
        elif token == "-":
            print("    addi a0, a0, ", "-" + get_token(s, i))
        else:
            print("    Error: invalid token")
            break

    print("    ret")