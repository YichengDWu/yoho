#!/bin/bash
assert() {
    expected="$1"
    input="$2"

    echo -e "$input" > tmp.mojo
    ./yoho tmp.mojo tmp.s
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

assert 0 'fn main() -> Int:\n    return 0'
assert 42 'fn main() -> Int:\n    return 42'
assert 21 'fn main() -> Int:\n    return 5+20-4'
assert 41 'fn main() -> Int:\n     return 12 + 34 - 5 ' 
assert 47 'fn main() -> Int:\n    return 5+6*7'
assert 15 'fn main() -> Int:\n    return 5*(9-6)'
assert 4 'fn main() -> Int:\n    return (3+5)/2'
assert 10 'fn main() -> Int:\n    return -10+20'
assert 10 'fn main() -> Int:\n    return - -10'
assert 10 'fn main() -> Int:\n    return - - +10'

assert 0 'fn main() -> Int:\n    return 0==1'
assert 1 'fn main() -> Int:\n    return 42==42'
assert 1 'fn main() -> Int:\n    return 0!=1'
assert 0 'fn main() -> Int:\n    return 42!=42'

assert 1 'fn main() -> Int:\n    return 0<1'
assert 0 'fn main() -> Int:\n    return 1<1'
assert 0 'fn main() -> Int:\n    return 2<1'
assert 1 'fn main() -> Int:\n    return 0<=1'
assert 1 'fn main() -> Int:\n    return 1<=1'
assert 0 'fn main() -> Int:\n    return 2<=1'

assert 1 'fn main() -> Int:\n    return 1>0'
assert 0 'fn main() -> Int:\n    return 1>1'
assert 0 'fn main() -> Int:\n    return 1>2'
assert 1 'fn main() -> Int:\n    return 1>=0'
assert 1 'fn main() -> Int:\n    return 1>=1'
assert 0 'fn main() -> Int:\n    return 1>=2'

assert 3 "fn main() -> Int:\n    1\n\n    2\n    return 3"
assert 2 "fn main() -> Int:\n    1+3\n    3<1\n    return 3-1"

assert 6 "fn main() -> Int:\n    var a=1\n    var b=1\n    a=b=3\n    return a+b"


echo OK 