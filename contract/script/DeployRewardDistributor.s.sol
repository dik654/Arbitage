// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../src/contracts/rewardDistribution/RewardDistributor.sol";

// forge clean && forge script DeployRewardDistributorScript --rpc-url https://eth-sepolia.g.alchemy.com/v2/<API_KEY> --verify --etherscan-api-key <ETHERSCAN_API_KEY> --broadcast --account deployAccount --sender <ADDRESS> --ffi

contract DeployRewardDistributorScript is Script {
    uint256 deployerPrivateKey;
    address REWARD;

    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        REWARD = vm.envAddress("REWARD");
    }

    function run() public {
        vm.broadcast(deployerPrivateKey);
        address rewardDistributorProxy = Upgrades.deployTransparentProxy(
            "RewardDistributor.sol",
            vm.addr(deployerPrivateKey),
            abi.encodeCall(RewardDistributor.initialize, (vm.addr(deployerPrivateKey), address(REWARD)))
        );
        address adminAddress = Upgrades.getAdminAddress(rewardDistributorProxy);
        address implementationAddress = Upgrades.getImplementationAddress(rewardDistributorProxy);
        console.log("REWARD_DISTRIBUTOR_PROXY: ", address(rewardDistributorProxy));
        console.log("REWARD_DISTRIBUTOR_IMPLEMENTATION: ", address(implementationAddress));
        console.log("REWARD_DISTRIBUTOR_ADMIN: ", address(adminAddress));
    }
}
