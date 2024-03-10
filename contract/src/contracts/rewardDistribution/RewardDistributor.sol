// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/IRewardDistributor.sol";
import "../interfaces/IERC20.sol";

contract RewardDistributor is IRewardDistributor {
    address public rewardToken;
    

    function claim() external {
        
    }

    function updateInvestorInfo(address investor, uint allocPoint) external {

    }
    
    function notifyReward(uint amount) external {

    }

}
