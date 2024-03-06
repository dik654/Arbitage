// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Setup.sol";

contract SampleTest is Setup {
    address sampleUser = address(0x9999);

    // 각 토큰의 가격을 확인하는 테스트 (per ether)
    function testShowPrices() public {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        uint[] memory amountsOut;

        path[1] = address(FIRE);
        amountsOut = router02.getAmountsOut(1 ether, path); // 10 ether를 경로에 따라 스왑합니다.
        console.log("FIRE   : ", amountsOut[1]);

        path[1] = address(WATER);
        amountsOut = router02.getAmountsOut(1 ether, path);
        console.log("WATER  : ", amountsOut[1]);

        path[1] = address(WIND);
        amountsOut = router02.getAmountsOut(1 ether, path);
        console.log("WIND   : ", amountsOut[1]);

        path[1] = address(EARTH);
        amountsOut = router02.getAmountsOut(1 ether, path);
        console.log("EARTH  : ", amountsOut[1]);

    }

    // 토큰별로 10 ether만큼 매수하는 테스트
    function testBuyTokens() public {
        _testSampleBase();
        address[] memory path = new address[](2);
        path[0] = address(WETH);

        vm.startPrank(sampleUser); // sampleUser 지갑에 연결되었다고 가정합니다.
        {
            path[1] = address(FIRE); // path를 [WETH, FIRE]로 설정합니다.
            router02.swapExactETHForTokens{value: 10 ether}(0, path, sampleUser, block.timestamp); // 10 ether를 경로에 따라 스왑합니다.
            path[1] = address(WATER);
            router02.swapExactETHForTokens{value: 10 ether}(0, path, sampleUser, block.timestamp);
            path[1] = address(WIND);
            router02.swapExactETHForTokens{value: 10 ether}(0, path, sampleUser, block.timestamp);
            path[1] = address(EARTH);
            router02.swapExactETHForTokens{value: 10 ether}(0, path, sampleUser, block.timestamp);
        }
        vm.stopPrank(); // 지갑연결을 해제합니다. (해제해야 다른 지갑에 연결할 수 있어요.)

        // 밸런스를 출력합니다.
        console.log("FIRE  : ", balance(sampleUser, address(FIRE)));
        console.log("WATER : ", balance(sampleUser, address(WATER)));
        console.log("WIND  : ", balance(sampleUser, address(WIND)));
        console.log("EARTH : ", balance(sampleUser, address(EARTH)));

        reset();
    }

    function _testSampleBase() private {
        // sampleUser가 40 ether 가지고 있다고 가정합니다.
        _charge(address(0), sampleUser, 40 ether);
    }
}
