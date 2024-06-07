from sys import argv


fn main() raises:
    if len(argv()) != 2:
        raise Error("invalid number of arguments")

    print(".global  main")
    print("main:")
    print("    li a0, ", argv()[1])
    print("    ret\n")
