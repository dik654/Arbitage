// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IArbitrageur {
    function arbitrage(address[] memory _path) external;
}