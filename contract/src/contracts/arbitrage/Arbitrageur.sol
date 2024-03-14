// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/IArbitrageur.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Callee.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../libraries/UniswapV2Library.sol";

contract Arbitrageur is IArbitrageur, IUniswapV2Callee {
    address public owner;
    address public factory;

    error AlreadyInitialized();
    error NoProfit();

    /**
     * @notice  initialize variables
     * @dev     set variables instead of constructor on UUPS
     * @param   _owner  contract owner address
     * @param   _factory  uniswap v2 factory address
     */
    function intialize(address _owner, address _factory) public {
        if (owner != address(0)) {
            revert AlreadyInitialized();
        }
        owner = _owner;
        factory = _factory;
    }

    /**
     * @notice  initiate arbitrage swap process
     * @dev     borrow asset from "swap function" to get arbitrage profit by uniswapV2Call callback process
     * @param   _amountIn  asset amount to borrow
     * @param   _path  arbitrage swap path
     */
    function arbitrage(
        uint256 _amountIn,
        address[] memory _path
    ) public {
        // -- arbitrage --
        // getAmountsOut으로 차익거래 과정에서의 모든 amountOut 얻기
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(factory, _amountIn, _path);
        // 차익 거래 실행에 앞서 getAmountsOut <= _amount + fee라면 revert(수익이 나지않는 경우 revert)
        uint256 fee = (_amountIn * 3) / 997 + 1;
        uint256 amountToRepay = _amountIn + fee;
        if (amounts[_path.length - 1] - amountToRepay == 0) {
            revert NoProfit();
        }
        // swap(0, amountOut, 콜백주소, uniswapV2Call에서 연속적으로 실행할 swap path bytes)
        address pair = UniswapV2Library.pairFor(factory, _path[0], _path[1]);
        // 0, 1중 어떤게 path[1]인지 검사
        uint256 amount0Out;
        uint256 amount1Out;
        {
        (address input, address output) = (_path[0], _path[1]);
        (address token0,) = UniswapV2Library.sortTokens(input, output);
        uint256 amountOut = amounts[1];
        (amount0Out, amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
        }
        UniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), encodeData(pair, amountToRepay, amounts, _path));
    }

    /**
     * @notice  initiate arbitrage swap process on callback
     * @dev     arbitrage swap and repayment process
     * @param   _amount0  asset amount to borrow
     * @param   _amount1  asset amount to borrow
     * @param   _data  encoded data for repayment and arbitrage swap
     */
    function uniswapV2Call(address /* _sender */, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        // -- uniswapV2Call --
        (address pair, uint256 amountToRepay, uint256[] memory amounts, address[] memory path) = decodeData(_data);
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

    /**
     * @notice  arbitrage swap process
     * @dev     arbitrage swap process
     * @param   amounts  arbitrage swap path amounts
     * @param   path  arbitrage swap path
     * @param   _to  address to send swapped token after swap function executed
     */
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
     * @notice  encode necessary data
     * @dev     encode necessary data to arbitrage swap and repayment
     * @param   _pair  token pool where you borrowed
     * @param   _amountToRepay  borrowed token amount + fee
     * @param   _amounts  arbitrage swap path amounts
     * @param   _path  arbitrage swap path
     * @return  data  encoded data
     */
    function encodeData(address _pair, uint256 _amountToRepay, uint256[] memory _amounts, address[] memory _path) internal pure returns (bytes memory data) {
        data = abi.encode(_pair, _amountToRepay, _amounts, _path);
    }


    /**
     * @notice  decode necessary data
     * @dev     decode necessary data to arbitrage swap and repayment
     * @param   _data  encoded data
     * @return  address  pair
     * @return  uint256  amountToRepay
     * @return  uint256[]  amounts
     * @return  address[]  path
     */
    function decodeData(bytes calldata _data) internal pure returns (address, uint256, uint256[] memory, address[] memory) {
        return abi.decode(_data, (address, uint256, uint256[], address[]));
    }
}
