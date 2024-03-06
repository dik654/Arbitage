// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPriceFeed {
  event AssetPriceUpdated(address asset, uint256 price, uint256 timestamp);
  event EthPriceUpdated(uint256 price, uint256 timestamp);

  function getAssetPrice(address asset) external view returns (uint256);
  function setAssetPrice(address asset, uint256 price) external;
  function healthCheck() external view returns (bool);
}