// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import "../Setup.sol";
import "../mock/Setup.sol";
import "../../src/contracts/libraries/UniswapV2Library.sol";

// forge test --mc ArbitrageTest -vv
// forge test --mc --fork-url https://mainnet.infura.io/v3/API_KEY -vv


contract ArbitrageTest is Setup {
    function testArbitrage() public view {
        console.log("ETH  : ", balance(user, address(0)));
        console.log("FIRE  : ", balance(user, address(FIRE)));
        console.log("WATER : ", balance(user, address(WATER)));
        console.log("WIND  : ", balance(user, address(WIND)));
        console.log("EARTH : ", balance(user, address(EARTH)));
    }

    function testGetReserves() public view {
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

    function testFlashswap() public {
        vm.startPrank(deployer);
        IERC20(address(FIRE)).approve(address(arbitrageur), 10000 ether);
        IERC20(address(WETH)).approve(address(arbitrageur), 10000 ether);
        address pair = UniswapV2Library.pairFor(address(factory), address(FIRE), address(WETH));
        address[] memory path = new address[](2);
        path[0] = address(FIRE);
        path[1] = address(WETH);
        arbitrageur.arbitrage(path);
        vm.stopPrank();
    }
}