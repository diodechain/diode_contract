.PHONY: all
all: compile

.PHONY: compile
compile:
	forge compile

.PHONY: test
test:
	forge test -vvv

.PHONY: test-gas
test-gas:
	forge test --match-contract DiodeRegistryLightGas -vv

.PHONY: lint
lint:
	forge lint contracts test/*.sol

.PHONY: clean
clean:
	-rm -rf out
