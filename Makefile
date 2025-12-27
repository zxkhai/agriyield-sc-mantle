.PHONY: test test-units test-kyc test-yield test-vault

# Run all tests
test:
	forge test

# Run only unit tests
test-units:
	./test-units.sh

# Run individual unit tests
test-kyc:
	forge test test/units/KYCRegistry.t.sol

test-kyc-verb:
	forge test test/units/KYCRegistry.t.sol -vvvv

test-yield:
	forge test test/units/YieldNote.t.sol

test-yield-verb:
	forge test test/units/YieldNote.t.sol -vvvv

test-vault:
	forge test test/units/AgriVault.t.sol

test-vault-verb:
	forge test test/units/AgriVault.t.sol -vvvv