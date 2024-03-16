// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../Setup.sol";
import "forge-std/console.sol";
import "../../../src/contracts/mock/DistributeMock.sol";

// forge test --mc MockRewardDistributionMockTest -vv --ffi

contract RewardDistributionMockTest is Setup {

    function test_RewardDistribution() public {
        vm.startPrank(deployer);
        DistributeMock distributeMock = new DistributeMock();
        rewardDistributor.updateInvestorInfo(deployer, 10);
        rewardDistributor.updateInvestorInfo(investor1, 20);
        rewardDistributor.updateInvestorInfo(investor2, 30); 
        rewardDistributor.updateInvestorInfo(investor3, 40);

        IERC20(address(REWARD)).approve(address(distributeMock), 10000000 ether);
        vm.stopPrank();

        distributeMock.initiate(address(REWARD), deployer, address(rewardDistributor), 10000000 ether);
        vm.prank(deployer);
        rewardDistributor.claim();
        vm.prank(investor1);
        rewardDistributor.claim();
        vm.prank(investor2);
        rewardDistributor.claim();
        vm.prank(investor3);
        rewardDistributor.claim();

        console.log("==RewardDistribution Test ==");
        console.log("deployer : ", REWARD.balanceOf(deployer));
        console.log("investor1: ", REWARD.balanceOf(investor1));
        console.log("investor2: ", REWARD.balanceOf(investor2));
        console.log("investor3: ", REWARD.balanceOf(investor3));
    }
}
