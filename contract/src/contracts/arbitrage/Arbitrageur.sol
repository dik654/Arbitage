// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/IArbitrageur.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Callee.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../libraries/UniswapV2Library.sol";

contract Arbitrageur is IArbitrageur, IUniswapV2Callee {
    address public factory;
    address public repayPair;
    address public repayToken;

    error AlreadyInitialized();
    error NoProfit();

    /**
     * @notice  .
     * @dev     .
     * @param   _factory  .
     */
    function intialize(address _factory) {
        if (owner != address(0)) {
            revert AlreadyInitialized();
        }
        factory = _factory;
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _amount  .
     * @param   _path  .
     */
    function arbitrage(
        uint256 _amountIn,
        address[] calldata _path
    ) external {
        // -- arbitrage --
        // getAmountsOut으로 차익거래 과정에서의 모든 amountOut 얻기
        uint256[] amounts = UniswapV2Library.getAmountsOut(factory, _amountIn, _path);
        // 차익 거래 실행에 앞서 getAmountsOut <= _amount + fee라면 revert(수익이 나지않는 경우 revert)
        uint256 fee = (_amountIn * 3) / 997 + 1;
        uint256 amountToRepay = _amountIn + fee;
        if (amounts[_path.length - 1] - amountToRepay == 0) {
            revert NoProfit();
        }
        // swap(0, amountOut, 콜백주소, uniswapV2Call에서 연속적으로 실행할 swap path bytes)
        address pair = UniswapV2Library.pairFor(factory, _path[0], _path[1]);
        // 0, 1중 어떤게 path[1]인지 검사
        (address input, address output) = (path[0], path[1]);
        (address token0,) = UniswapV2Library.sortTokens(input, output);
        uint256 amountOut = amounts[i + 1];
        (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
        UniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), encodeData(pair, amountToRepay, amounts, _path));
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _amount0  .
     * @param   _amount1  .
     * @param   _data  .
     */
    function uniswapV2Call(address /* _sender */, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        // -- uniswapV2Call --
        (address pair, uint256 amountToRepay, uint256[] amounts, address[] path) = decodeData(_data);
        // flash swap 이후의 arbitrage swap 과정을 실행하여 차익 거래 실행
        uint256[] memory newAmounts = new uint256[](amounts.length - 1);
        for (uint256 i = 1; i < amounts.length; i++) {
            newAmounts[i - 1] = amounts[i];
        }
        address[] memory newPath = new address[](path.length - 1);
        for (uint256 i = 1; i < path.length; i++) {
            newPath[i - 1] = path[i];
        }
        _swap(newAmounts, newPath, address(this));
        // 차익 거래 실행 후 _amount + fee만큼 arbitrage에서 빌린 pool에 갚기
        IERC20(path[0]).transfer(pair, amountToRepay);
        // RewardDistributor로 차익 전송
    }

    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _path  .
     * @return  data  .
     */
    function encodeData(address pair, uint256 amountToRepay, uint256[] calldata amountArray, address[] calldata _path) internal pure returns (bytes memory data) {
        data = abi.encode(pair, amountToRepay, amountArray, _path);
    }

    /**
     * @notice  .
     * @dev     .
     * @param   data  .
     * @return  address[]  .
     */
    function decodeData(bytes calldata _data) internal pure returns (address, uint256, uint256[], address[]) {
        return abi.decode(_data, (address, uint256, uint256[], address[]));
    }
}
