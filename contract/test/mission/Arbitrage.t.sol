// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../Setup.sol";

contract ArbitrageTest is Setup {

    function testArbitrageSample() public {
        console.log("ETH  : ", balance(user, address(0)));
        console.log("FIRE  : ", balance(user, address(FIRE)));
        console.log("WATER : ", balance(user, address(WATER)));
        console.log("WIND  : ", balance(user, address(WIND)));
        console.log("EARTH : ", balance(user, address(EARTH)));
    }
}
