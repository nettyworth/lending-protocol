// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol';


library NFTfiSigningUtils {

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
        uint256 rePayment;
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
        uint256 rePayment;
        uint256 loanDuration;
        uint256 nonce;
    }

    struct LoanCollectionOffer {
        address collectionAddress;
        address erc20TokenAddress;
        address lender;
        uint256 loanAmount;
        uint256 rePayment;
        uint256 loanDuration;
        uint256 nonce;
    }

    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function isValidateLoanCollectionOfferSignature(
       bytes memory _lenderSignature,
       LoanCollectionOffer calldata collectionOffer
    ) public view returns(bool) {
        if(collectionOffer.lender == address(0)){
            return false;
        } else {
            uint256 chainId;
            chainId = getChainID();
            bytes32 message = keccak256(abi.encodePacked(
                collectionOffer.collectionAddress,
                collectionOffer.erc20TokenAddress,
                collectionOffer.lender,
                collectionOffer.loanAmount,
                collectionOffer.rePayment,
                collectionOffer.loanDuration,
                collectionOffer.nonce,
                chainId
            ));

            bytes32 messageWithEthSignPrefix = message.toEthSignedMessageHash();

            return (messageWithEthSignPrefix.recover(_lenderSignature) == collectionOffer.lender);
        }
    }

    function isValidateRequestLoanSignature(
        bytes memory _borrowerSignature,
        LoanRequest calldata loanRequest
    ) public view returns(bool) {
        if(loanRequest.borrower == address(0)){
            return false;
        } else {
            uint256 chainId;
            chainId = getChainID();
            bytes32 message = keccak256(abi.encodePacked(
                loanRequest.tokenId,
                loanRequest.nftContractAddress,
                loanRequest.erc20TokenAddress,
                loanRequest.borrower,
                loanRequest.loanAmount,
                loanRequest.rePayment,
                loanRequest.loanDuration,
                loanRequest.nonce,
                chainId
            ));

            bytes32 messageWithEthSignPrefix = message.toEthSignedMessageHash();

            return (messageWithEthSignPrefix.recover(_borrowerSignature) == loanRequest.borrower);
        }
    }

    function isValidateSignatureApprovalOffer(
       bytes memory _lenderSignature,
       LoanOffer calldata loanOffer
    ) public view returns(bool) {
        if(loanOffer.lender == address(0)){
            return false;
        } else {
            uint256 chainId;
            chainId = getChainID();
            bytes32 message = keccak256(abi.encodePacked(
                loanOffer.tokenId,
                loanOffer.nftContractAddress,
                loanOffer.erc20TokenAddress,
                loanOffer.lender,
                loanOffer.borrower,
                loanOffer.loanAmount,
                loanOffer.rePayment,
                loanOffer.loanDuration,
                loanOffer.nonce,
                chainId
            ));

            bytes32 messageWithEthSignPrefix = message.toEthSignedMessageHash();

            return (messageWithEthSignPrefix.recover(_lenderSignature) == loanOffer.lender);
        }
    }
}