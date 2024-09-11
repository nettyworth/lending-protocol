// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EIP712Verifier {

    bytes32 public DOMAIN_SEPARATOR;

    string public constant NAME = "MyEIP712Verifier";
    string public constant VERSION = "1";
    uint256 public constant CHAIN_ID = 1;
    address public constant VERIFYING_CONTRACT = address(this);

    bytes32 public constant VERIFY_TYPEHASH = keccak256(
        "Verify(address sender,address recipient,uint256 amount,uint256 nonce,uint256 expiry)"
    );

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                CHAIN_ID,
                VERIFYING_CONTRACT
            )
        );
    }

    struct VerifyData {
        address sender;
        address recipient;
        uint256 amount;
        uint256 nonce;
        uint256 expiry;
    }

    function verify(
        address sender,
        address recipient,
        uint256 amount,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(
                VERIFY_TYPEHASH,
                sender,
                recipient,
                amount,
                nonce,
                expiry
            )
        );

        // Hash the EIP-712 message
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );

        address recoveredSigner = ecrecover(digest, v, r, s);

        return recoveredSigner == sender;
    }
}
