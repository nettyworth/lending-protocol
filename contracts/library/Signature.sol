// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

library Signature {
    function verify(
        address signer,
        bytes memory signature,
        uint256 amount
    ) internal view returns (bool) {
        bytes32 payload = keccak256(abi.encode(msg.sender, amount));
        bytes32 message = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", payload)
        );

        return _verifyHashSignature(signer, message, signature);
    }

    function _verifyHashSignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address recoverySigner = address(0);

        if (v == 27 || v == 28) {
            recoverySigner = ecrecover(hash, v, r, s);
        }

        return signer == recoverySigner;
    }
}
