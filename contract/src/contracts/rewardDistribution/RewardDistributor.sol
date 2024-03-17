// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "../interfaces/IRewardDistributor.sol";

contract RewardDistributor is IRewardDistributor, Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    address public rewardToken;
    uint256 public remainingReward;
    uint256 public totalAllocPoint;
    mapping(address => uint256) userReward;
    EnumerableSet.AddressSet private _addressSet;
    EnumerableMap.AddressToUintMap private _allocMap;

    event IncreasedReward(uint256 amount);

    error OnlyInvestor();
    error OnlyAuthorizedContract();
    error ZeroAmount();
    error NotImplementPermit(address);

    modifier onlyInvestor {
        (bool included, ) = _allocMap.tryGet(msg.sender);
        if (!included) revert OnlyInvestor();
        _;
    }

    modifier onlyAuthorizedContract {
        if (!_addressSet.contains(msg.sender)) revert OnlyAuthorizedContract();
        _;
    }

    /**
     * @notice  initialize variables
     * @dev     set variables instead of constructor on UUPS
     * @param   _owner  contract owner
     */
    function initialize(address _owner, address _rewardToken) public initializer {
        __Ownable_init(_owner);
        rewardToken = _rewardToken;
    }

    function addAuthorizedContract(address _address) public onlyOwner returns (bool) {
        return _addressSet.add(_address);
    }

    function removeAuthorizedContract(address _address) public onlyOwner returns (bool) {
        return _addressSet.remove(_address);
    }

    /**
     * @notice  investor claims their own rewards
     * @dev     investor receive as much as their shares
     */
    function claim() public onlyInvestor {
        // Check Effect Interaction
        uint256 claimAmount = userReward[msg.sender];
        userReward[msg.sender] -= claimAmount; 
        IERC20(rewardToken).safeTransfer(msg.sender, claimAmount);
    }

    /**
     * @notice  set address as investor
     * @dev     save investor address on storage and set their shares
     * @param   _investor  investor address
     * @param   _allocPoint  investing share
     */
    function updateInvestorInfo(address _investor, uint256 _allocPoint) public onlyOwner {
        (bool included, uint256 userAllocPoint) = _allocMap.tryGet(_investor);
        // 기존 investor라면
        if (included) {
            // total allocPoint에서 기존 investor의 allocPoint를 빼고 업데이트되는 allocPoint 값을 추가할 준비
            totalAllocPoint -= userAllocPoint;
            // 만약 업데이트 되는 값이 0이라면 지분이 없어진 것이므로 기존에 받지 않은 지분을 remainingReward로 이동 
            // 및 investor map에서 삭제
            if (_allocPoint == 0) {
                remainingReward += userReward[_investor];
                userReward[_investor] = 0;
                _allocMap.remove(_investor);
                // 업데이트 되는 값이 0이므로 바로 종료
                return;
            }
        // 새로운 investor라면
        } else {
            // 업데이트되는 allocPoint가 0이라면 investor map에 추가하지않고 종료
            if (_allocPoint == 0) return;
            // 새 investor를 investor map에 추가
            _allocMap.set(_investor, _allocPoint);
        }
        // total allocPoint에 업데이트되는 allocPoint 값을 실제로 추가
        totalAllocPoint += _allocPoint;
    }

    /**
     * @notice  owner notify rewards added on this contract
     * @dev     distribute rewards to investors and emit event
     * @dev     Rewards that are not divided by investor length will be added to remainingReward
     * @param   _amount  increased rewards amount
     */
    function notifyReward(uint256 _amount) external onlyAuthorizedContract {
        if (_amount == 0) revert ZeroAmount();
        distributeReward(_amount);
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        emit IncreasedReward(_amount);
    }

    /**
     * @notice  owner notify rewards added on this contract with permit
     * @dev     distribute rewards to investors and emit event with permit
     * @dev     Rewards that are not divided by investor length will be added to remainingReward
     * @param   _amount  increased rewards amount
     * @param   _owner  param for permit
     * @param   _spender  param for permit
     * @param   _value  param for permit
     * @param   _deadline  param for permit
     * @param   _v  param for permit
     * @param   _r  param for permit
     * @param   _s  param for permit
     */
    function notifyRewardPermit(
        uint256 _amount,
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external onlyAuthorizedContract {
        if (_amount == 0) revert ZeroAmount();
        distributeReward(_amount);
        try IERC20Permit(rewardToken).permit(_owner, _spender, _value, _deadline, _v, _r, _s) {
            IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
            emit IncreasedReward(_amount);
        } catch {
            revert NotImplementPermit(rewardToken);
        }
    }

    /**
     * @notice  distribute rewards to investors
     * @dev     distribute rewards to investors based on their shares
     * @param   _amount  amount to distribute
     */
    function distributeReward(uint256 _amount) internal {
        address[] memory investors = _allocMap.keys();
        uint256 distributed;
        for (uint256 i = 0; i < investors.length; i++) {
            uint256 userAllocPoint = _allocMap.get(investors[i]);
            uint256 distributeAmount = _amount * userAllocPoint / totalAllocPoint;
            userReward[investors[i]] = distributeAmount;
            distributed += distributeAmount;
        }
        remainingReward += _amount - distributed;
    }

    /**
     * @notice  distribute remaining rewards to investors
     * @dev     owner distribute remaining rewards to investors
     */
    function distributeRemaining() public onlyOwner {
        distributeReward(remainingReward);
    }
}
