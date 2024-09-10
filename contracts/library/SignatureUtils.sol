// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;
 
library SignatureUtils {

    struct NftDeposit {
        address nftContractAddress;
        uint256 tokenId;
        address borrower;
    }
    
    struct LoanRequest {
        uint256 tokenId;           
        address nftContractAddress;
        address erc20TokenAddress;
        address borrower;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 loanDuration;
        uint256 nonce;
    }

    struct LoanOffer {
        uint256 tokenId;           
        address nftContractAddress;
        address erc20TokenAddress;
        address lender;
        address borrower;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 loanDuration;
        uint256 nonce;
    }

    struct LoanCollectionOffer {
        address collectionAddress;
        address erc20TokenAddress;
        address lender;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 loanDuration;
        uint256 nonce;
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
 
    function validateNftDepositSignature(
        bytes calldata signature,
        address _contract,
        uint256 _tokenId,
        address _borrower
    ) public pure returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(abi.encode(_contract, _tokenId, _borrower));
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(_borrower, candidateHash, signature);
    }

    function validateLoanCollectionOfferSignature(
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
                collectionOffer.interestRate,
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

    function validateRequestLoanSignature(
        bytes calldata signature,
        LoanRequest calldata loanRequest
    ) internal pure returns (bool) {
        // Pack the 
                bytes32 freshHash = keccak256(
            abi.encode(
                loanRequest.tokenId,
                loanRequest.nftContractAddress,
                loanRequest.erc20TokenAddress,
                loanRequest.borrower,
                loanRequest.loanAmount,
                loanRequest.interestRate,
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
 
    function validateSignatureApprovalOffer(   
        bytes calldata signature,
        LoanOffer calldata loanOffer
    ) internal pure returns (bool) {
 
        // Verify if the fresh hash is signed with the provided signature

    return _verifyHashSignature(loanOffer.lender, keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(
            abi.encode(
                loanOffer.tokenId,
                loanOffer.nftContractAddress,
                loanOffer.erc20TokenAddress,
                loanOffer.lender,
                loanOffer.borrower,
                loanOffer.loanAmount,
                loanOffer.interestRate,
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