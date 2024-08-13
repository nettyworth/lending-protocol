// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Modifiers
 * @dev Modifiers that will help simplify the contract code.
 */
abstract contract Modifiers {
    /**
     * @dev Requirement for non-zero address.
     */
    modifier noZeroAddress(address _address) {
        require(_address != address(0), "Address cannot be zero");
        _;
    }

    /**
     * @dev Requirement for non-empty uint256 value.
     */
    modifier noZeroValue(uint _value) {
        require(_value > 0, "Value cannot be zero");
        _;
    }
}
