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

assert 0 'return 0'
assert 42 'return 42'
assert 21 'return 5+20-4'
assert 41 ' return 12 + 34 - 5 ' 
assert 47 'return 5+6*7'
assert 15 'return 5*(9-6)'
assert 4 'return (3+5)/2'
assert 10 'return -10+20'
assert 10 'return - -10'
assert 10 'return - - +10'

assert 0 'return 0==1'
assert 1 'return 42==42'
assert 1 'return 0!=1'
assert 0 'return 42!=42'

assert 1 'return 0<1'
assert 0 'return 1<1'
assert 0 'return 2<1'
assert 1 'return 0<=1'
assert 1 'return 1<=1'
assert 0 'return 2<=1'

assert 1 'return 1>0'
assert 0 'return 1>1'
assert 0 'return 1>2'
assert 1 'return 1>=0'
assert 1 'return 1>=1'
assert 0 'return 1>=2'

assert 3 "1\n2\nreturn 3"
assert 2 "1+3\n3<1\nreturn 3-1"

assert 3 "a=3\nreturn a"
assert 8 "a=3\nz=5\nreturn a+z"
assert 3 "foo=3\nreturn foo"
assert 8 "foo123=3\nbar=5\nreturn foo123+bar"
assert 6 "a=b=3\nreturn a+b"

assert 1 'return 1\n2\n3'
assert 2 '1\nreturn 2\n3'
assert 3 '1\n2\nreturn 3'

assert 3 'if 0:\n    return 2\nreturn 3'
assert 3 'if 1-1:\n    return 2\nreturn 3'
assert 2 'if 1:\n    return 2\nreturn 3'
assert 2 'if 2-1:\n    return 2\nreturn 3'
assert 4 'if 0:\n    1\n    2\n    return 3\nelse:\n    return 4'
assert 3 'if 1:\n    1\n    2\n    return 3\nelse:\n    return 4'
assert 0 'x = 10\ny = 20\nif x == 10:\n    x = 5\n    if y == 20:\n        x = 0\nreturn x'

echo OK 