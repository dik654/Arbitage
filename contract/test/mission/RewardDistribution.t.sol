// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import "../Setup.sol";
import "../mock/Setup.sol";

// forge test --mt testRewardDistribution -vv
// forge test --fork-url https://mainnet.infura.io/v3/API_KEY

contract RewardDistributionTest is Setup {

    function testRewardDistributionSample() public view {
        console.log("==RewardDistribution Test ==");
        console.log("deployer : ", REWARD.balanceOf(deployer));
        console.log("investor1: ", REWARD.balanceOf(investor1));
        console.log("investor2: ", REWARD.balanceOf(investor2));
        console.log("investor3: ", REWARD.balanceOf(investor3));
    }
}
