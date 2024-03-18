// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/contracts/uniswap/UniswapV2Factory.sol";
import "../../src/contracts/uniswap/UniswapV2Router02.sol";
import "../../src/contracts/mock/TestERC20Permit.sol";
import "../../src/contracts/mock/TestERC20.sol";
import "../../src/contracts/mock/WETH9.sol";
import "../../src/contracts/arbitrage/MockArbitrageur.sol";
import "../../src/contracts/rewardDistribution/RewardDistributor.sol";
import "../../src/contracts/mock/DistributeMock.sol";
import "../../src/contracts/interfaces/IUniswapV2Pair.sol";
import "../../src/contracts/interfaces/IWETH.sol";
    
contract SetupAddresses is Test {
    using ECDSA for bytes32;

    address deployer;
    address user;
    address investor1;
    address investor2;
    address investor3;
    address signer;

    uint256 constant SIGNER_PRIVATE_KEY = 0xabc123;

    UniswapV2Factory factory;
    UniswapV2Router02 router02;

    MockArbitrageur arbitrageur;
    RewardDistributor rewardDistributor;
    RewardDistributor rewardDistributorPermit;
    DistributeMock distributeMock;

    WETH9 WETH;
    TestERC20 FIRE;
    TestERC20 WATER;
    TestERC20 WIND;
    TestERC20 EARTH;
    TestERC20 REWARD;
    TestERC20Permit REWARD_PERMIT;

    function setupAddresses() internal {
        deployer = address(0xdeff);
        user = address(0x1234);
        investor1 = address(0x1111);
        investor2 = address(0x2222);
        investor3 = address(0x3333);
        signer = vm.addr(SIGNER_PRIVATE_KEY);

        vm.startPrank(deployer);
        {
            WETH = new WETH9();
            factory = new UniswapV2Factory(address(deployer));
            router02 = new UniswapV2Router02(address(factory), address(WETH));
            
            FIRE = new TestERC20("FIRE", "FIRE", 18);
            WATER = new TestERC20("WATER", "WATER", 18);
            WIND = new TestERC20("WIND", "WIND", 18);
            EARTH = new TestERC20("EARTH", "EARTH", 6);
            REWARD = new TestERC20("REWARD", "REWARD", 18);
            REWARD_PERMIT = new TestERC20Permit();

            distributeMock = new DistributeMock();
            
            address arbitrageurProxy = Upgrades.deployTransparentProxy(
                "MockArbitrageur.sol",
                deployer,
                abi.encodeCall(MockArbitrageur.initialize, (deployer, address(factory)))
            );
            arbitrageur = MockArbitrageur(arbitrageurProxy);
            address rewardDistributorProxy = Upgrades.deployTransparentProxy(
                "RewardDistributor.sol",
                deployer,
                abi.encodeCall(RewardDistributor.initialize, (deployer, address(REWARD)))
            );
            rewardDistributor = RewardDistributor(rewardDistributorProxy);
            address rewardDistributorPermitProxy = Upgrades.deployTransparentProxy(
                "RewardDistributor.sol",
                deployer,
                abi.encodeCall(RewardDistributor.initialize, (deployer, address(REWARD_PERMIT)))
            );
            rewardDistributorPermit = RewardDistributor(rewardDistributorPermitProxy);
        }
        vm.stopPrank();
    }

}

