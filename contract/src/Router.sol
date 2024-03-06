// SPDX-License-Identifier: GLP v3.0
pragma solidity ^0.8.19;

import "./interfaces/IFactory.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ICPMM.sol";
import "./libraries/CPMMLibrary.sol";

contract Router is IRouter {
    address public immutable override factory;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'ROUTER: EXPIRED');
        _;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = CPMMLibrary.pairFor(factory, tokenA, tokenB);
        require(IERC20(tokenA).transferFrom(msg.sender, pair, amountA), "AddLiquidity: fail to send tokenA to pair");
        require(IERC20(tokenB).transferFrom(msg.sender, pair, amountB), "AddLiquidity: fail to send tokenB to pair");
        liquidity = ICPMM(pair).mint(to);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) private returns (uint256 amountA, uint256 amountB) {
        if (IFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = CPMMLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = CPMMLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'ROUTER:INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = CPMMLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'ROUTER:INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = CPMMLibrary.pairFor(factory, tokenA, tokenB);
        (uint256 amount0, uint256 amount1) = ICPMM(pair).burn(to, liquidity);
        (address token0,) = CPMMLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'ROUTER:INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'ROUTER:INSUFFICIENT_B_AMOUNT');
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = CPMMLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'ROUTER:INSUFFICIENT_OUTPUT_AMOUNT');
        IERC20(path[0]).transferFrom(msg.sender, CPMMLibrary.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }

    function _swap(uint256[] memory amounts, address[] memory path, address _to) private {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = CPMMLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? CPMMLibrary.pairFor(factory, output, path[i + 2]) : _to;
            ICPMM(CPMMLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function getQuote(uint256 _amountA, uint256 _amountB, address _tokenA, address _tokenB) public view returns (address token0, address token1, uint256 optimal0, uint256 optimal1) {
        address pair = CPMMLibrary.pairFor(factory, _tokenA, _tokenB);
        uint256 amount0;
        uint256 amount1;

        if (_tokenA < _tokenB) {
            token0 = _tokenA;
            token1 = _tokenB;
            amount0 = _amountA;
            amount1 = _amountB;
        } else {
            token0 = _tokenB;
            token1 = _tokenA;
            amount0 = _amountB;
            amount1 = _amountA;
        }
        (uint112 reserve0, uint112 reserve1, )= ICPMM(pair).getReserves();
        optimal0 = quote(amount1, uint256(reserve1), uint256(reserve0));
        optimal1 = quote(amount0, uint256(reserve0), uint256(reserve1));
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) public pure override returns (uint amountB) {
        return CPMMLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure override returns (uint amountOut) {
        return CPMMLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint256 amountOut, uint reserveIn, uint reserveOut) public pure override returns (uint amountIn) {
        return CPMMLibrary.getAmountOut(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path) public view override returns (uint[] memory amounts) {
        return CPMMLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path) public view override returns (uint[] memory amounts) {
        return CPMMLibrary.getAmountsIn(factory, amountOut, path);
    }
}