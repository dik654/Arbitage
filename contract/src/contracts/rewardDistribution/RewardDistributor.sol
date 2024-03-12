// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/IRewardDistributor.sol";
import "../interfaces/IERC20.sol";

contract RewardDistributor is IRewardDistributor {
    address public owner;
    address public rewardToken;
    uint256 public totalReward;
    uint256 public totalAllocPoint;
    mapping(address => uint256) allocPoint;

    error AlreadyInitialized();
    error OnlyOwner();
    error FailToSendReward();

    function initialize(address _owner) {
        if (owner != address(0)) {
            revert AlreadyInitialized();
        }
        owner = _owner;
    }

    function updateOwner(address _owner) {
        if (owner != msg.sender) {
            revert OnlyOwner();
        }
        owner = _owner;
    }

    /**
     * @notice  .
     * @dev     .
     */
    function claim() external {
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 userAllocPoint = allocPoint[msg.sender]; 
            uint256 userReward = totalReward * (userAllocPoint / totalAllocPoint);
            if (!IERC20.transfer(msg.sender, userReward)) {
                revert FailToSendReward();
            }
        }
    }

    /**
     * @notice  .
     * @dev     .
     * @param   investor  .
     * @param   _allocPoint  .
     */
    function updateInvestorInfo(address investor, uint256 _allocPoint) external {
        totalAllocPoint -= allocPoint[_investor];
        totalAllocPoint += _allocPoint;
        allocPoint[_investor] = _allocPoint;
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _amount  .
     */
    function notifyReward(uint256 _amount) external {
        if (!IERC20(rewardToken).transferFrom(owner, address(this), _amount)) {
            revert FailToSendReward();
        }
        totalReward += _amount;
    }
}
