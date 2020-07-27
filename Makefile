TRUFFLE := node_modules/.bin/truffle
DOCGEN := ./node_modules/.bin/solidity-docgen

deps := $(patsubst src/deps/%,contracts/deps/%,$(wildcard src/deps/*.sol))
contracts := $(patsubst src/%,contracts/%,$(wildcard src/*.sol))
test_contracts := $(patsubst test/%,contracts/%,$(wildcard test/*.sol))

prod := $(deps) $(contracts)

.PHONY: all
all: compile

contracts:
	mkdir -p contracts

contracts/deps: contracts
	mkdir -p contracts/deps

contracts/%.sol: src/%.sol contracts/deps
	sed -e 's:TEST_IF:TEST_IF\*/:g' -e 's:TEST_ELSE\*/:TEST_ELSE:g' $< > $@

contracts/%.sol: test/%.sol contracts/deps
	cp $< $@

.PHONY: compile
compile: $(prod) $(test_contracts)
	$(TRUFFLE) compile

.PHONY: docs
docs: $(prod)
	$(DOCGEN)

.PHONY: test
test: $(test_contracts) $(prod)
	$(TRUFFLE) test
	# $(TRUFFLE) test test/solidity_test.js

.PHONY: clean
clean:
	-rm -rf build contracts
