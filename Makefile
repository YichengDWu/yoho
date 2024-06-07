yoho: main.mojo
	mojo build -o $@ $^

test: yoho
	./test.sh

clean:
	rm -f yoho tmp*

.PHONY: test clean 