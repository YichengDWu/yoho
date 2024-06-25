#!/bin/bash
assert() {
    expected="$1"
    input="$2"

    ./yoho "$input" > tmp.s
    riscv64-unknown-elf-gcc -static -o tmp tmp.s
    ./tmp
    actual="$?"

    if [ "$actual" = "$expected" ]; then
        echo -e "$input\n=> $actual\n"
    else
        echo -e "$input\n=> $expected expected, but got $actual\n"
        exit 1
    fi
}

assert 0 0
assert 42 42
assert 21 "5+20-4"
assert 41 " 12 + 34 - 5 "

echo OK 