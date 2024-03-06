// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../Setup.sol";

contract RewardDistributionTest is Setup {

    function testRewardDistributionSample() public {
        console.log("==RewardDistribution Test ==");
        console.log("deployer : ", REWARD.balanceOf(deployer));
        console.log("investor1: ", REWARD.balanceOf(investor1));
        console.log("investor2: ", REWARD.balanceOf(investor2));
        console.log("investor3: ", REWARD.balanceOf(investor3));
    }
}
