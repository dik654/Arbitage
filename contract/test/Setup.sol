// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./SetupAddresses.sol";

contract Setup is Test, SetupAddresses {
    using stdStorage for StdStorage;

    uint256 private _setupSnapshotId;

    receive() external payable {}

    function setUp() public {
        setupAddresses();
        _addLiquidity();
        _chargeUserBalance();

        _setupSnapshotId = vm.snapshot();
    }


    function _addLiquidity() private {
        deal(deployer, 10000000 ether);
        vm.startPrank(deployer);
        {
            IWETH(address(WETH)).deposit{value: 10000000 ether}();
            FIRE.mint(deployer, 10000000 ether);
            WATER.mint(deployer, 10000000 ether);
            WIND.mint(deployer, 10000000 ether);
            EARTH.mint(deployer, 10000000e6);
            REWARD.mint(deployer, 10000000 ether);

            WETH.approve(address(router02), UINT256_MAX);
            FIRE.approve(address(router02), UINT256_MAX);
            WATER.approve(address(router02), UINT256_MAX);
            WIND.approve(address(router02), UINT256_MAX);
            EARTH.approve(address(router02), UINT256_MAX);

            router02.addLiquidity(address(FIRE), address(WETH), 100000 ether, 1200000 ether, 0, 0, deployer, block.timestamp); // 12
            router02.addLiquidity(address(WATER), address(WETH), 100000 ether, 90000 ether, 0, 0, deployer, block.timestamp); // 9
            router02.addLiquidity(address(WIND), address(WETH), 100000 ether, 2100000 ether, 0, 0, deployer, block.timestamp); // 21
            router02.addLiquidity(address(EARTH), address(WETH), 100000e6, 100000 ether, 0, 0, deployer, block.timestamp); // 1

            router02.addLiquidity(address(FIRE), address(WATER), 88000 ether, 1300000 ether, 0, 0, deployer, block.timestamp);
            router02.addLiquidity(address(FIRE), address(WIND), 2400000 ether, 1010000 ether, 0, 0, deployer, block.timestamp);
            router02.addLiquidity(address(FIRE), address(EARTH), 90000 ether, 1320000e6, 0, 0, deployer, block.timestamp);
            router02.addLiquidity(address(WATER), address(WIND), 1980000 ether, 91000 ether, 0, 0, deployer, block.timestamp);
            router02.addLiquidity(address(WATER), address(EARTH), 99000 ether, 90000e6, 0, 0, deployer, block.timestamp);
            router02.addLiquidity(address(WIND), address(EARTH), 99100 ether, 2090000e6, 0, 0, deployer, block.timestamp);
        }
        vm.stopPrank();
    }

    function _chargeUserBalance() private {
        vm.startPrank(deployer);
        {
            deal(user, 100000 ether);
            FIRE.mint(user, 100000 ether);
            WATER.mint(user, 100000 ether);
            WIND.mint(user, 100000 ether);
            EARTH.mint(user, 100000e6);

        }
        vm.stopPrank();
    }

    // 토큰을 user에게 가상으로 지급하는 함수
    function _charge(address token, address user, uint amount) internal {
        if (token == address(0)) {
            deal(user, amount);
        } else {
            deal(token, user, amount);
        }
    }

    // account의 token 보유수량을 반환하는 함수
    function balance(address account, address token) internal view returns (uint) {
        if (token == address(0)) {
            return address(account).balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    // 테스트 시작 전으로 환경을 되돌리는 함수.
    function reset() internal {
        vm.revertTo(_setupSnapshotId);
        _setupSnapshotId = vm.snapshot();
    }
}

