# Arbitrage

## Installation
curl -L https://foundry.paradigm.xyz | bash
foundryup

## Test
```bash
cd contract
forge install
forge remappings > remappings.txt

forge clean && forge test --mc ArbitrageMockTest -vv --ffi
forge clean && forge test --mc RewardDistributionMockTest -vv --ffi
forge clean && forge test --mc ArbitrageTest --fork-url https://mainnet.infura.io/v3/API_KEY -vv --ffi
forge test --mc RewardDistributionTest --fork-url https://mainnet.infura.io/v3/API_KEY -vv --ffi
```

## Deployment
write .env file based on .env.example
```bash
forge clean && forge script script/DeployArbitrageurScript.s.sol:DeployArbitrageurScript --rpc-url <API_KEY> --sender <PUBLIC_ADDRESS> --ffi --broadcast
forge clean && forge script script/DeployRewardDistributor.s.sol:DeployRewardDistributorScript --rpc-url https://eth-sepolia.g.alchemy.com/v2/<API_KEY> --sender <PUBLIC_ADDRESS> --ffi --broadcast
```
