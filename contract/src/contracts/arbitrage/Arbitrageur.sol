// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/IArbitrageur.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2Callee.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../libraries/UniswapV2Library.sol";

contract Arbitrageur is IArbitrageur, IUniswapV2Callee {
    address public factory;
    address public repayPair;
    address public repayToken;
    uint256 public amountToRepay;

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
        uint256 _amount,
        address[] memory _path
    ) external {
        // -- arbitrage --
        // getAmountOut으로 차익거래 시작 토큰 _amount에서 다음 토큰 개수 amountOut 얻기
        // swap(0, amountOut, 콜백주소, path bytes)
        // -- uniswapV2Call --
        // uniswapV2Call에 갚아야할 토큰 개수 _amount + fee 및
        // swapExactTokensForTokens를 실행하여 차익 거래 실행
        // 차익 거래 실행에 앞서 getAmountsOut <= _amount + fee라면 revert(수익이 나지않는 경우 revert)
        // 차익 거래 실행 후 _amount + fee만큼 arbitrage에서 빌린 pool에 갚기
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _amount0  .
     * @param   _amount1  .
     * @param   _data  .
     */
    function uniswapV2Call(address /* _sender */, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {

    }

    /**
     * @notice  .
     * @dev     .
     * @param   _path  .
     * @return  data  .
     */
    function encodePath(address[] memory _path) internal pure returns (bytes memory data) {
        if (_path.length < 2) return new bytes(0);

        // address[] memory newPath = new address[](_path.length - 1);
        // for (uint i = 1; i < _path.length; i++) {
        //     newPath[i - 1] = _path[i];
        // }

        // data = abi.encode(newPath);
        data = abi.encode(_path);
        return data;
    }

    /**
     * @notice  .
     * @dev     .
     * @param   data  .
     * @return  address[]  .
     */
    function decodeData(bytes calldata data) internal pure returns (address[] memory) {
        address[] memory decodedPath = abi.decode(data, (address[]));
        return decodedPath;
    }
}
