// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IRewardDistributor.sol";

contract DistributeMock is ReentrancyGuard {
    using SafeERC20 for IERC20;

    function initiate(address _tokenAddress, address _from, address _rewardDistributor, uint256 _amount) public nonReentrant {
        // approve부터 사용까지 한 트랜잭션이므로 front running 불가
        IERC20(_tokenAddress).approve(_rewardDistributor, _amount);
        IRewardDistributor(_rewardDistributor).notifyReward(_amount);
    }

    function initiatePermit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
        ) public nonReentrant {
        IRewardDistributor(_spender).notifyRewardPermit(
            _owner, 
            _spender, 
            _value, 
            _deadline, 
            _v, 
            _r, 
            _s
        );
    }
}