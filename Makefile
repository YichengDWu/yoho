SRC_FILES := $(wildcard src/yoho/*.mojo)

yoho: main.mojo $(SRC_FILES)
	mojo build -I src -o $@ $<

parser:
	mojo run -I src generate_parser.mojo "test/calc.gram" "src/yoho/parser.mojo"
	mojo format src/yoho/parser.mojo

test: yoho
	mojo test -I src test
	./test.sh

clean:
	rm -f yoho tmp* test/temp*

.PHONY: test clean 