.PHONY: all
all: compile docs

.PHONY: precompile
precompile:
	./precompile.sh

.PHONY: compile
compile: precompile
	npm run compile


.PHONY: docs
docs: precompile
	npm run docs

.PHONY: test
test: compile
	npm run test_remix
	npm run test

.PHONY: clean
clean:
	-rm -rf build contracts
