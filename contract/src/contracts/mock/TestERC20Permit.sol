// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TestERC20Permit is ERC20, ERC20Permit {
    constructor() ERC20("REWARD", "REWARD") ERC20Permit("REWARD") {}

    function mint(address _account, uint256 _amount) public {
        _mint(_account, _amount);
    }
}