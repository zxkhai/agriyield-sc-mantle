.PHONY: test test-units test-integration test-kyc test-yield test-vault

# Run all tests
test-all:
	forge test


# Run main test agriyield smart contracts
test:
	forge test test/AgriYield.t.sol

test-verb:
	forge test test/AgriYield.t.sol -vvvv


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