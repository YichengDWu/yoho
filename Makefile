SRC_FILES := $(wildcard src/yoho/*.mojo)

yoho: main.mojo $(SRC_FILES)
	mojo build -I src -o $@ $<

test: yoho
	./test.sh

clean:
	rm -f yoho tmp*

.PHONY: test clean 