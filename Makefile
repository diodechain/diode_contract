PRE := cat

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
	$(PRE) $< > $@

contracts/%.sol: test/%.sol contracts/deps
	cp $< $@

.PHONY: compile
compile: $(prod)
	forge compile

.PHONY: test
test: PRE := sed -e 's:TEST_IF:TEST_IF\*/:g' -e 's:TEST_ELSE\*/:TEST_ELSE:g'
test: $(test_contracts) $(prod)
	forge test

.PHONY: compile_test
compile_test: PRE := sed -e 's:TEST_IF:TEST_IF\*/:g' -e 's:TEST_ELSE\*/:TEST_ELSE:g'
compile_test: $(test_contracts) $(prod)
	forge compile

.PHONY: clean
clean:
	-rm -rf build contracts
