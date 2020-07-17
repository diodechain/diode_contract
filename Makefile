.PHONY: all
all:
	npm run compile

.PHONY: test
test: all
	npm run test

.PHONY: clean
clean:
	-rm -rf build contracts
