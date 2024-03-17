// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../src/contracts/arbitrage/MockArbitrageur.sol";

// forge clean && forge script DeployArbitrageurScript --rpc-url https://eth-sepolia.g.alchemy.com/v2/<API_KEY> --verify --etherscan-api-key <ETHERSCAN_API_KEY> --broadcast --ffi

contract DeployArbitrageurScript is Script {
    uint256 deployerPrivateKey;
    address factory;
    function setUp() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        factory = vm.envAddress("FACTORY");
    }

    function run() public {
        vm.broadcast(deployerPrivateKey);
        address arbitrageurProxy = Upgrades.deployTransparentProxy(
            "MockArbitrageur.sol",
            vm.addr(deployerPrivateKey),
            abi.encodeCall(MockArbitrageur.initialize, (vm.addr(deployerPrivateKey), address(factory)))
        );
        address adminAddress = Upgrades.getAdminAddress(arbitrageurProxy);
        address implementationAddress = Upgrades.getImplementationAddress(arbitrageurProxy);
        console.log("ARBITRAGEUR_PROXY: ", address(arbitrageurProxy));
        console.log("ARBITRAGEUR_PROXY_IMPLEMENTATION: ", address(implementationAddress));
        console.log("ARBITRAGEUR_PROXY_ADMIN: ", address(adminAddress));
    }
}
