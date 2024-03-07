// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Callee.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../libraries/UniswapV2Library.sol";

contract Arbitrageur is IUniswapV2Callee {
    address public factory;
    address public repayPair;
    address public repayToken;
    uint256 public amountToRepay;

    error NoProfit();

    constructor(address _factory) {
        factory = _factory;
    }

    function arbitrage(
        address[] memory _path,
        bytes calldata _data
    ) external {
        (address token0, address token1) = UniswapV2Library.sortTokens(_path[0], _path[1]);
        repayPair = UniswapV2Library.pairFor(factory, token0, token1);
        (uint256 reserve0, uint256 reserve1) = UniswapV2Library.getReserves(factory, token0, token1);
        // TODO 최적의 교환비로 교환하기 위해 대출할 토큰의 양 계산방법 고안
        if (token0 == _path[0]) {
            reserve1 = UniswapV2Library.getAmountOut(reserve0 - 1, reserve0, reserve1);
            reserve0 = reserve0 - 1;
            repayToken = token0;
            amountToRepay = reserve0 - 1;
        } else {
            reserve0 = UniswapV2Library.getAmountOut(reserve1 - 1, reserve1, reserve0);
            reserve1 = reserve1 - 1;
            repayToken = token1;
            amountToRepay = reserve1 - 1;
        }
        IUniswapV2Pair(repayPair).swap(reserve0, reserve1, address(this), _data);
    }

    function uniswapV2Call(address /* _sender */, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        address[] memory path = decodeData(_data);
        if (path.length > 1) {
            (address token0, address token1) = UniswapV2Library.sortTokens(path[0], path[1]);
            address pair = UniswapV2Library.pairFor(factory, token0, token1);
            (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory, path[0], path[1]);
            (reserveA, reserveB) = token0 == path[0] ? (_amount0, uint256(0)) : (uint256(0), _amount1); 
            UniswapV2Pair(pair).swap(reserveA, reserveB, address(this), encodePath(path));
        } else {
            uint256 balance = IERC20(repayToken).balanceOf(address(this));
            uint256 fee = (amountToRepay * 3) / 997 + 1;
            amountToRepay = amountToRepay + fee;
            IERC20(repayToken).transfer(repayPair, amountToRepay);
            if (balance - amountToRepay > 0) {
                revert NoProfit();
            }
        }
    }

    function encodePath(address[] memory _path) internal pure returns (bytes memory data) {
        if (_path.length < 2) return new bytes(0);

        address[] memory newPath = new address[](_path.length - 1);
        for (uint i = 1; i < _path.length; i++) {
            newPath[i - 1] = _path[i];
        }

        data = abi.encode(newPath);
        return data;
    }

    function decodeData(bytes calldata data) internal pure returns (address[] memory) {
        address[] memory decodedPath = abi.decode(data, (address[]));
        return decodedPath;
    }


}
