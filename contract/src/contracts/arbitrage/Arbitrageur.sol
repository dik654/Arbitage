// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IArbitrageur.sol";
import "../interfaces/IUniswapV2Callee.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../libraries/UniswapV2Library.sol";

contract Arbitrageur is IArbitrageur, IUniswapV2Callee, Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    address public factory;

    error NoProfit();

    /**
     * @notice  initialize variables
     * @dev     set variables instead of constructor on UUPS
     * @param   _owner  contract owner address
     * @param   _factory  uniswap v2 factory address
     */
    function initialize(address _owner, address _factory) public initializer {
        __Ownable_init(_owner);
        factory = _factory;
    }

    /**
     * @notice  initiate arbitrage swap process
     * @dev     borrow asset from "swap function" to get arbitrage profit by uniswapV2Call callback process
     * @param   _amountBorrow  asset amount to borrow
     * @param   _path  arbitrage swap path
     */
    function arbitrage(
        uint256 _amountBorrow,
        address[] memory _path
    ) public onlyOwner {
        // getAmountsOut으로 차익거래 과정에서의 모든 amountOut 얻기
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(factory, _amountBorrow, _path);
        // 빌린 양을 바탕으로 uniswapV2Call에서 얼마나 갚아야하는지 계산
        uint256 fee = (_amountBorrow * 3) / 997 + 1;
        uint256 amountToRepay = _amountBorrow + fee;
        // 만약 결과 개수가 초기 빌린 개수 + 0.3% fee보다 작거나 같다면
        // 수익이 나지 않았으므로 revert
        if (amounts[_path.length - 1] <= amountToRepay) revert NoProfit();
        address pair = UniswapV2Library.pairFor(factory, _path[0], _path[1]);
        uint256 amount0Out;
        uint256 amount1Out;
        // stack too deep 방지용 Local Scope
        {
        (address input, address output) = (_path[0], _path[1]);
        (address token0,) = UniswapV2Library.sortTokens(input, output);
        uint256 amountOut = amounts[1];
        // 0, 1중 어떤게 path[1]인지 검사
        // token0이 시작 토큰(_path[0])이라면 (시작 0, 다음 amountOut)
        // amountOut은 빌리거나 제공한 토큰으로 교환한 토큰 개수
        (amount0Out, amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
        }
        // 차익교환 실행
        // swap(0, amountOut, 콜백주소, uniswapV2Call에서 사용할 bytes 데이터)
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), encodeData(pair, amountToRepay, amounts, _path));
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
        IERC20(newPath[0]).safeTransfer(
            UniswapV2Library.pairFor(factory, newPath[0], newPath[1]), newAmounts[0]
        );
        _swap(newAmounts, newPath, address(this));
        // 차익 거래 실행 후 _amount + fee만큼 arbitrage에서 빌린 pool에 갚기
        IERC20(path[0]).safeTransfer(pair, amountToRepay);
        // RewardDistributor로 차익 전송
        // uint256 profitAmount = IERC20(path[0]).balanceOf(this(address));
        // TODO path[0] 토큰을 rewardToken으로 사용하는 rewardDistributor 주소를 리턴하는 getRewardDistributor함수
        // IRewardDistributor(getRewardDistributor(path[0])).notifyReward(profitAmount);
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
