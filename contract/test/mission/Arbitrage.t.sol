// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import "../Setup.sol";
import "../mock/Setup.sol";

// forge test --mt testArbitrage -vv
// forge test --mt --fork-url https://mainnet.infura.io/v3/API_KEY

contract ArbitrageTest is Setup {

    function testArbitrageSample() public view {
        console.log("ETH  : ", balance(user, address(0)));
        console.log("FIRE  : ", balance(user, address(FIRE)));
        console.log("WATER : ", balance(user, address(WATER)));
        console.log("WIND  : ", balance(user, address(WIND)));
        console.log("EARTH : ", balance(user, address(EARTH)));
    }
}
