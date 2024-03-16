// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IRewardDistributor.sol";

contract DistributeMock {
    using SafeERC20 for IERC20;

    function initiate(address _tokenAddress, address _from, address _rewardDistributor, uint256 _amount) public {
        IERC20(_tokenAddress).safeTransferFrom(_from, _rewardDistributor, _amount);
        IRewardDistributor(_rewardDistributor).notifyReward(_amount);
    }
}