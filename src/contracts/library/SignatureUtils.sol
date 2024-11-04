// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;
 
library SignatureUtils {    
    struct LoanRequest {
        uint256[] tokenIds;           
        address nftContractAddress;
        address erc20TokenAddress;
        address borrower;
        uint256 loanAmount;
        uint256 aprBasisPoints;
        uint256 loanDuration;
        uint256 nonce;
    }

    struct LoanOffer {
        uint256[] tokenIds;           
        address nftContractAddress;
        address erc20TokenAddress;
        address lender;
        address borrower;
        uint256 loanAmount;
        uint256 aprBasisPoints;
        uint256 loanDuration;
        uint256 nonce;
    }

    struct LoanCollectionOffer {
        address collectionAddress;
        address erc20TokenAddress;
        address lender;
        uint256 loanAmount;
        uint256 aprBasisPoints;
        uint256 loanDuration;
        uint256 nonce;
    }

    function _validateLoanCollectionOfferSignature(
        bytes calldata signature,
        LoanCollectionOffer calldata collectionOffer
    ) internal pure returns (bool) {
        // Pack the 
                bytes32 freshHash = keccak256(
            abi.encode(
                collectionOffer.collectionAddress,
                collectionOffer.erc20TokenAddress,
                collectionOffer.lender,
                collectionOffer.loanAmount,
                collectionOffer.aprBasisPoints,
                collectionOffer.loanDuration,
                collectionOffer.nonce
            )
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(collectionOffer.lender, candidateHash, signature);
    }
     
    function _validateRequestLoanSignature(
        bytes calldata signature,
        LoanRequest calldata loanRequest
    ) internal pure returns (bool) {
        // Pack the 
                bytes32 freshHash = keccak256(
            abi.encode(
                loanRequest.tokenIds,
                loanRequest.nftContractAddress,
                loanRequest.erc20TokenAddress,
                loanRequest.borrower,
                loanRequest.loanAmount,
                loanRequest.aprBasisPoints,
                loanRequest.loanDuration,
                loanRequest.nonce
            )
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(loanRequest.borrower, candidateHash, signature);
    }
 
    function _validateSignatureApprovalOffer(   
        bytes calldata signature,
        LoanOffer calldata loanOffer
    ) internal pure returns (bool) {
 
        // Verify if the fresh hash is signed with the provided signature

    return _verifyHashSignature(loanOffer.lender, keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(
            abi.encode(
                loanOffer.tokenIds,
                loanOffer.nftContractAddress,
                loanOffer.erc20TokenAddress,
                loanOffer.lender,
                loanOffer.borrower,
                loanOffer.loanAmount,
                loanOffer.aprBasisPoints,
                loanOffer.loanDuration,
                loanOffer.nonce
            )
        ))
        ), signature);
    }

//********************************Verify Signatures********************************//
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