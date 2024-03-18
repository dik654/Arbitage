// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../Setup.sol";

// forge clean && forge test --mc ArbitrageTest --fork-url https://mainnet.infura.io/v3/API_KEY -vv --ffi

contract ArbitrageTest is Setup {
    function test_GetReserves() public view {
        (uint256 amountA, uint256 amountB) = UniswapV2Library.getReserves(address(factory), address(FIRE), address(WETH));
        console.log("FIRE WETH : ", amountA, " ", amountB);
        (amountA, amountB) = UniswapV2Library.getReserves(address(factory), address(WATER), address(WETH));
        console.log("WATER WETH : ", amountA, " ", amountB);
        (amountA, amountB) = UniswapV2Library.getReserves(address(factory), address(WIND), address(WETH));
        console.log("WIND WETH : ", amountA, " ", amountB);
        (amountA, amountB) = UniswapV2Library.getReserves(address(factory), address(EARTH), address(WETH));
        console.log("EARTH WETH : ", amountA, " ", amountB);
        (amountA, amountB) = UniswapV2Library.getReserves(address(factory), address(FIRE), address(WATER));
        console.log("FIRE WATER : ", amountA, " ", amountB);
        (amountA, amountB) = UniswapV2Library.getReserves(address(factory), address(FIRE), address(WIND));
        console.log("FIRE WIND : ", amountA, " ", amountB);
        (amountA, amountB) = UniswapV2Library.getReserves(address(factory), address(FIRE), address(EARTH));
        console.log("FIRE EARTH : ", amountA, " ", amountB);
        (amountA, amountB) = UniswapV2Library.getReserves(address(factory), address(WATER), address(WIND));
        console.log("WATER WIND : ", amountA, " ", amountB);
        (amountA, amountB) = UniswapV2Library.getReserves(address(factory), address(WATER), address(EARTH));
        console.log("WATER EARTH : ", amountA, " ", amountB);
        (amountA, amountB) = UniswapV2Library.getReserves(address(factory), address(WIND), address(EARTH));
        console.log("WIND EARTH : ", amountA, " ", amountB);
    }

    function test_Arbitrage() public {
        vm.startPrank(deployer);
        address[] memory path = new address[](4);
        path[0] = address(FIRE);
        path[1] = address(WATER);
        path[2] = address(WETH);
        path[3] = address(FIRE);
        arbitrageur.arbitrage(283 ether, path);
        console.log("arbitrage:%d", IERC20(address(FIRE)).balanceOf(address(arbitrageur)));
        vm.stopPrank();
    }

    function test_AlreadyInitialized() public {
        vm.prank(deployer);
        vm.expectRevert(
            abi.encodeWithSignature("InvalidInitialization()")
        ); 
        arbitrageur.initialize(deployer, address(factory));
    } 

    function test_OnlyOwner() public {
        address[] memory path = new address[](4);
        path[0] = address(FIRE);
        path[1] = address(WATER);
        path[2] = address(WETH);
        path[3] = address(FIRE);
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user)
        );
        vm.prank(user);
        arbitrageur.arbitrage(283 ether, path);
    }

    function test_NoProfit() public {
       vm.startPrank(deployer);
        address[] memory path = new address[](4);
        path[0] = address(FIRE);
        path[1] = address(WATER);
        path[2] = address(WETH);
        path[3] = address(FIRE);
        vm.expectRevert(
            abi.encodeWithSignature("NoProfit()")
        );
        arbitrageur.arbitrage(100000 ether, path);
        vm.stopPrank(); 
    }

    function testFail_WrongPath() public {
        vm.startPrank(deployer);
        address[] memory path = new address[](1);
        path[0] = address(FIRE);
        arbitrageur.arbitrage(283 ether, path);
        vm.stopPrank();
    }
}
