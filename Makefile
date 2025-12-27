.PHONY: test test-units test-integration test-kyc test-yield test-vault

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

# Generate gas report
gas:
	forge test --gas-report
	forge snapshot --snap .gas.baseline


# Deploy contracts
deploy-dry:
	forge script script/DAgriYield.s.sol:DeployAgriYield --rpc-url $(MANTLE_SEPOLIA_RPC)

deploy:
	forge script script/DAgriYield.s.sol:DeployAgriYield --rpc-url $(MANTLE_SEPOLIA_RPC) --broadcast -vvvv

# Verify contracts on Mantle Explorer
verify:
	forge verify-contract --chain mantle-sepolia $(KYC_REGISTRY_ADDRESS) src/KYCRegistry.sol:KYCRegistry $(ETHERSCAN_API_KEY)
	forge verify-contract --chain mantle-sepolia $(YIELD_NOTE_NFT_ADDRESS) src/YieldNote.sol:YieldNote $(ETHERSCAN_API_KEY)
	forge verify-contract --chain mantle-sepolia $(AGRI_VAULT_ADDRESS) src/AgriVault.sol:AgriVault $(ETHERSCAN_API_KEY)