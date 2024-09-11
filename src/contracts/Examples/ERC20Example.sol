// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NettyWorthToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("nettyWorthEr20", "NW") {
        _mint(msg.sender, initialSupply * (10 ** uint256(decimals())));
    }
}
