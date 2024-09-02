// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
 
library SignatureUtils {

    struct NftDeposit {
        address nftContractAddress;
        uint256 tokenId;
        address borrower;
    }

    struct RequestLoan {
        uint256 tokenId;
        address nftContractAddress;
        address erc20TokenAddrss;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 loanDuration;
        uint256 borrowerNonce;
        address borrower;
    }

    struct LoanOffer {
        uint256 tokenId;
        address nftContractAddress;
        address erc20TokenAddrss;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 loanDuration;
        address lender;
        uint256 lenderNonce;
        address borrower;
    }

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
 
 
    function validateSignature(
        bytes calldata signature,
        address _contract,
        uint256 tokenId,
        address _sender
    ) public pure returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(abi.encode(_contract, tokenId, _sender));
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(_sender, candidateHash, signature);
    }
 
    function validateSignatureOffer(
        bytes calldata signature,
        uint256 tokenId,
        address _contract,
        address _erc20Token,
        uint256 _loanAmount,
        uint256 _interestRate,
        uint256 _loanDuration,
        uint256 _borrowerNonce,
        address _signer
    ) internal pure returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(
            abi.encode(
                tokenId,
                _contract,
                _erc20Token,
                _loanAmount,
                _interestRate,
                _loanDuration,
                _borrowerNonce,
                _signer
            )
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(_signer, candidateHash, signature);
    }
 
 
    function validateSignatureApprovalOffer(   
        bytes calldata signature,
        uint256 tokenId,
        address _contract,
        address _erc20Token,
        uint256 _loanAmount,
        uint256 _interestRate,
        uint256 _loanDuration,
        address _lender,
        uint256 _nonce,
        address _borrower
 
    ) internal pure returns (bool) {
 
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(_lender, keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(
            abi.encode(
                tokenId,
                _contract,
                _erc20Token,
                _loanAmount,
                _interestRate,
                _loanDuration,
                _lender,
                _nonce,
                _borrower
            )
        ))
        ), signature);
    }
 
    function _verifyHashSignature(
        address secret,
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
 
        address _signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            _signer = ecrecover(hash, v, r, s);
        }
        return secret == _signer;
    }
}