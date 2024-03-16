# Arbitage

## Installation
curl -L https://foundry.paradigm.xyz | bash
foundryup

## Test
cd contract
forge install
forge remappings > remappings.txt

forge clean && forge test --mc ArbitrageTest -vv --ffi
forge clean && forge test --mc RewardDistributionTest -vv --ffi