// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IArbitrageur {
    function arbitrage(uint256 _amountBorrow, address[] memory _path) external;
}