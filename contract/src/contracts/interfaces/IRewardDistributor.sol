// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IRewardDistributor {
    function claim() external;
    function updateInvestorInfo(address investor, uint allocPoint) external;
    function notifyReward(uint amount) external;
    function notifyRewardPermit(
        uint256 amount,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}