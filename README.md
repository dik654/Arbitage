# Arbitage

## Installation
curl -L https://foundry.paradigm.xyz | bash
foundryup

## Test
cd contract
forge install
forge remappings > remappings.txt

forge clean && forge test --mc ArbitrageMockTest -vv --ffi
forge clean && forge test --mc RewardDistributionMockTest -vv --ffi
forge clean && forge test --mc ArbitrageTest --fork-url https://mainnet.infura.io/v3/API_KEY -vv --ffi
forge test --mc RewardDistributionTest --fork-url https://mainnet.infura.io/v3/API_KEY -vv --ffi