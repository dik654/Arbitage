// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../Setup.sol";

// forge test --mc RewardDistributionTest --fork-url https://mainnet.infura.io/v3/API_KEY -vv -ffi

contract RewardDistributionTest is Setup {

    function test_RewardDistribution() public {
        vm.startPrank(deployer);
        rewardDistributor.updateInvestorInfo(deployer, 10);
        rewardDistributor.updateInvestorInfo(investor1, 20);
        rewardDistributor.updateInvestorInfo(investor2, 30); 
        rewardDistributor.updateInvestorInfo(investor3, 40);

        rewardDistributor.addAuthorizedContract(address(distributeMock));
        IERC20(address(REWARD)).transfer(address(distributeMock), 10000000 ether);
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

    function test_AlreadyInitialized() public {
        vm.prank(deployer);
        vm.expectRevert(
            abi.encodeWithSignature("InvalidInitialization()")
        ); 
        rewardDistributor.initialize(deployer, address(REWARD));
    }

    function test_AddAuthorizedContractOnlyOwner() public {
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        vm.prank(user);
        rewardDistributor.addAuthorizedContract(address(distributeMock));
    }

    function test_RemoveAuthorizedContractOnlyOwner() public {
        vm.prank(deployer);
        rewardDistributor.addAuthorizedContract(address(distributeMock));
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        vm.prank(user);
        rewardDistributor.removeAuthorizedContract(address(distributeMock));
    }

    function test_UpdateInvestorInfoOnlyOwner() public {
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        vm.prank(user);
        rewardDistributor.updateInvestorInfo(investor1, 10); 
    }

    function test_DistributeRemainingOnlyOwner() public {
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        vm.prank(user); 
        rewardDistributor.distributeRemaining();
    }

    function test_NotifyRewardOnlyAuthorizedContract() public {
        vm.prank(deployer);
        IERC20(address(REWARD)).transfer(address(distributeMock), 10000000 ether);
        vm.expectRevert(
            abi.encodeWithSignature("OnlyAuthorizedContract()")
        );
        distributeMock.initiate(address(REWARD), deployer, address(rewardDistributor), 10000000 ether);
    }

    function test_NotifyRewardZeroAmount() public {
        vm.prank(deployer);
        rewardDistributor.addAuthorizedContract(address(distributeMock));
        vm.expectRevert(
            abi.encodeWithSignature("ZeroAmount()")
        );
        distributeMock.initiate(address(REWARD), deployer, address(rewardDistributor), 0);
    }

    function test_NotifyRewardPermit() public {

    }

    function test_NotifyRewardPermitNotImplementPermit() public {

    }
}
