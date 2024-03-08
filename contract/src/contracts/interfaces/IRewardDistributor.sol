// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IRewardDistributor {
    function claim() external;
    function updateInvestorInfo(address investor, uint allocPoint) external;
    function notifyReward(uint amount) external;
}