// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/contracts/mock/TestERC20.sol";
import "../src/contracts/arbitrage/Arbitrageur.sol";
import "../src/contracts/rewardDistribution/RewardDistributor.sol";
import "../src/contracts/interfaces/IUniswapV2Factory.sol";
import "../src/contracts/interfaces/IUniswapV2Router02.sol";
import "../src/contracts/interfaces/IUniswapV2Pair.sol";
import "../src/contracts/interfaces/IWETH.sol";

contract SetupAddresses is Test {
    address deployer;
    address user;
    address investor1;
    address investor2;
    address investor3;

    IUniswapV2Factory factory;
    IUniswapV2Router02 router02;

    Arbitrageur arbitrageur;
    RewardDistributor rewardDistributor;

    IERC20 WETH;
    TestERC20 FIRE;
    TestERC20 WATER;
    TestERC20 WIND;
    TestERC20 EARTH;
    TestERC20 REWARD;


    function setupAddresses() internal {
        deployer = address(0xdeff);
        user = address(0x1234);
        investor1 = address(0x1111);
        investor2 = address(0x2222);
        investor3 = address(0x3333);
        factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        WETH = IERC20(router02.WETH());

        vm.startPrank(deployer);
        {
            FIRE = new TestERC20("FIRE", "FIRE", 18);
            WATER = new TestERC20("WATER", "WATER", 18);
            WIND = new TestERC20("WIND", "WIND", 18);
            EARTH = new TestERC20("EARTH", "EARTH", 6);
            REWARD = new TestERC20("REWARD", "REWARD", 18);
            
            address arbitrageurProxy = Upgrades.deployTransparentProxy(
                "Arbitrageur.sol",
                msg.sender,
                abi.encodeCall(Arbitrageur.initialize, (msg.sender, address(factory)))
            );
            arbitrageur = Arbitrageur(arbitrageurProxy);
            address rewardDistributorProxy = Upgrades.deployTransparentProxy(
                "RewardDistributor.sol",
                msg.sender,
                abi.encodeCall(RewardDistributor.initialize, (msg.sender, address(REWARD)))
            );
            rewardDistributor = RewardDistributor(rewardDistributorProxy);
        }
        vm.stopPrank();
    }

}

