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

    event IncreasedReward(uint256 amount);

    error AlreadyInitialized();
    error OnlyOwner();
    error FailToSendReward();

    /**
     * @notice  initialize variables
     * @dev     set variables instead of constructor on UUPS
     * @param   _owner  contract owner
     */
    function initialize(address _owner) public {
        if (owner != address(0)) {
            revert AlreadyInitialized();
        }
        owner = _owner;
    }

    /**
     * @notice  change contract owner
     * @dev     only owner can change contract owner
     * @param   _owner  owner address to change
     */
    function updateOwner(address _owner) public {
        if (owner != msg.sender) {
            revert OnlyOwner();
        }
        owner = _owner;
    }

    /**
     * @notice  investor claims their own reward
     * @dev     investor receive as much as their share(allocPoint)
     */
    function claim() public {
        // TODO investor만 실행가능하도록
        uint256 userAllocPoint = allocPoint[msg.sender]; 
        uint256 userReward = totalReward * (userAllocPoint / totalAllocPoint);
        if (!IERC20(rewardToken).transfer(msg.sender, userReward)) {
            revert FailToSendReward();
        }
    }

    /**
     * @notice  set address as investor
     * @dev     save investor address on storage and set their share
     * @param   _investor  investor address
     * @param   _allocPoint  investing share
     */
    function updateInvestorInfo(address _investor, uint256 _allocPoint) public {
        totalAllocPoint -= allocPoint[_investor];
        totalAllocPoint += _allocPoint;
        allocPoint[_investor] = _allocPoint;
    }

    /**
     * @notice  owner send reward on this contract
     * @dev     send reward on this contract and emit event
     * @param   _amount  increased reward amount
     */
    function notifyReward(uint256 _amount) public {
        if (!IERC20(rewardToken).transferFrom(owner, address(this), _amount)) {
            revert FailToSendReward();
        }
        totalReward += _amount;
        emit IncreasedReward(_amount);
    }
}
