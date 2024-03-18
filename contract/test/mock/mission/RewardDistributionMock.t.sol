// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../Setup.sol";

// forge test --mc RewardDistributionMockTest -vv --ffi

contract RewardDistributionMockTest is Setup {
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

    function test_RewardDistributionPermit() public {
        vm.startPrank(deployer);
        rewardDistributorPermit.updateInvestorInfo(deployer, 10);
        rewardDistributorPermit.updateInvestorInfo(investor1, 20);
        rewardDistributorPermit.updateInvestorInfo(investor2, 30); 
        rewardDistributorPermit.updateInvestorInfo(investor3, 40);

        REWARD_PERMIT.mint(signer, 100 ether);
        rewardDistributorPermit.addAuthorizedContract(address(distributeMock));
        vm.stopPrank();

        uint256 deadline = block.timestamp + 60;
        bytes32 permitHash = _getPermitHash(
            signer,
            address(rewardDistributorPermit),
            100 ether,
            REWARD_PERMIT.nonces(signer),
            deadline
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            SIGNER_PRIVATE_KEY, permitHash
        );

        distributeMock.initiatePermit(
            signer,
            address(rewardDistributorPermit),
            100 ether,
            deadline,
            v,
            r,
            s
        );

        vm.prank(deployer);
        rewardDistributorPermit.claim();
        vm.prank(investor1);
        rewardDistributorPermit.claim();
        vm.prank(investor2);
        rewardDistributorPermit.claim();
        vm.prank(investor3);
        rewardDistributorPermit.claim();

        console.log("==RewardDistributionPermit Test ==");
        console.log("deployer : ", REWARD_PERMIT.balanceOf(deployer));
        console.log("investor1: ", REWARD_PERMIT.balanceOf(investor1));
        console.log("investor2: ", REWARD_PERMIT.balanceOf(investor2));
        console.log("investor3: ", REWARD_PERMIT.balanceOf(investor3));
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

    function test_FailNotifyRewardOnlyAuthorizedContract() public {
        vm.prank(deployer);
        IERC20(address(REWARD)).transfer(address(distributeMock), 10000000 ether);
        vm.expectRevert(
            abi.encodeWithSignature("OnlyAuthorizedContract()")
        );
        distributeMock.initiate(address(REWARD), deployer, address(rewardDistributor), 10000000 ether);
    }

    function test_FailNotifyRewardZeroAmount() public {
        vm.prank(deployer);
        rewardDistributor.addAuthorizedContract(address(distributeMock));
        vm.expectRevert(
            abi.encodeWithSignature("ZeroAmount()")
        );
        distributeMock.initiate(address(REWARD), deployer, address(rewardDistributor), 0);
    }

    function testFail_NotifyRewardPermit() public {
        vm.startPrank(deployer);
        uint256 deadline = block.timestamp + 60;
        REWARD_PERMIT.mint(signer, 100 ether);
        bytes32 permitHash = _getPermitHash(
            signer,
            address(rewardDistributor),
            10 ether,
            REWARD_PERMIT.nonces(signer),
            deadline
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            SIGNER_PRIVATE_KEY, permitHash
        );
        rewardDistributorPermit.addAuthorizedContract(address(distributeMock));
        distributeMock.initiatePermit(
            signer,
            address(rewardDistributorPermit),
            100 ether,
            deadline,
            v,
            r,
            s
        );
    }

    function test_FailNotifyRewardPermitNotImplementPermit() public {
        vm.startPrank(deployer);
        uint256 deadline = block.timestamp + 60;
        REWARD.mint(signer, 100 ether);
        bytes32 permitHash = _getPermitHash(
            signer,
            address(rewardDistributor),
            100 ether,
            REWARD_PERMIT.nonces(signer),
            deadline
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            SIGNER_PRIVATE_KEY, permitHash
        );
        rewardDistributor.addAuthorizedContract(address(distributeMock));
        vm.expectRevert(
            abi.encodeWithSignature("NotImplementPermit(address)", address(REWARD))
        );
        distributeMock.initiatePermit(
            signer,
            address(rewardDistributor),
            100 ether,
            deadline,
            v,
            r,
            s
        );
    }

    function _getPermitHash(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _nonce,
        uint256 _deadline
    ) private view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                REWARD_PERMIT.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256(
                            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                        ),
                        _owner,
                        _spender,
                        _value,
                        _nonce,
                        _deadline
                    )
                )
            )
        );
    }
}
