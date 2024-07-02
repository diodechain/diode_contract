.PHONY: all
all: compile

.PHONY: compile
compile:
	forge compile

.PHONY: test
test:
	forge test -vvv

.PHONY: clean
clean:
	-rm -rf out
