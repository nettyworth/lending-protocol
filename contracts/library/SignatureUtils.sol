// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
 
library SignatureUtils {

    struct NftDeposit {
        address nftContractAddress;
        uint256 tokenId;
        address borrower;
    }

    struct LoanOfferNative {
        uint256 tokenId;           
        address nftContractAddress;
        address lender;
        address borrower;
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

    function validateRequestLoanSignature(
        bytes calldata signature,
        LoanOffer calldata loanOffer

        // uint256 tokenId,
        // address _contract,
        // address _erc20Token,
        // uint256 _loanAmount,
        // uint256 _interestRate,
        // uint256 _loanDuration,
        // uint256 _borrowerNonce,
        // address _borrower
    ) internal pure returns (bool) {
        // Pack the 
                bytes32 freshHash = keccak256(
            abi.encode(
                loanOffer.tokenId,
                loanOffer.nftContractAddress,
                loanOffer.erc20TokenAddress,
                loanOffer.borrower,
                loanOffer.loanAmount,
                loanOffer.interestRate,
                loanOffer.loanDuration,
                loanOffer.nonce
            )
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(loanOffer.borrower, candidateHash, signature);


        // bytes32 freshHash = keccak256(
        //     abi.encode(
        //         tokenId,
        //         _contract,
        //         _erc20Token,
        //         _loanAmount,
        //         _interestRate,
        //         _loanDuration,
        //         _borrowerNonce,
        //         _borrower
        //     )
        // );
        // // Get the packed payload hash
        // bytes32 candidateHash = keccak256(
        //     abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        // );
        // // Verify if the fresh hash is signed with the provided signature
        // return _verifyHashSignature(_borrower, candidateHash, signature);
    }
 
    function validateSignatureApprovalOffer(   
        bytes calldata signature,
        // uint256 tokenId,
        // address _contract,
        // address _erc20Token,
        // uint256 _loanAmount,
        // uint256 _interestRate,
        // uint256 _loanDuration,
        // address _lender,
        // uint256 _nonce,
        // address _borrower
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

        // return _verifyHashSignature(_lender, keccak256(
        //     abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(
        //     abi.encode(
        //         tokenId,
        //         _contract,
        //         _erc20Token,
        //         _loanAmount,
        //         _interestRate,
        //         _loanDuration,
        //         _lender,
        //         _nonce,
        //         _borrower
        //     )
        // ))
        // ), signature);
    }


//********************************These signatures are used for native approval********************************//
    function validateRequestLoanSignature(
        bytes calldata signature,
        LoanOfferNative calldata loanOffer
    ) internal pure returns (bool) {
        // Pack the 
                bytes32 freshHash = keccak256(
            abi.encode(
                loanOffer.tokenId,
                loanOffer.nftContractAddress,
                loanOffer.borrower,
                // loanOffer.loanAmount, //Store the loan Amount in wei
                loanOffer.interestRate,
                loanOffer.loanDuration,
                loanOffer.nonce
            )
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(loanOffer.borrower, candidateHash, signature);
    }

    function validateSignatureApprovalOffer(   
        bytes calldata signature,
        LoanOfferNative calldata loanOffer
    ) internal pure returns (bool) {
 
            return _verifyHashSignature(loanOffer.lender, keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(
            abi.encode(
                loanOffer.tokenId,
                loanOffer.nftContractAddress,
                loanOffer.lender,
                loanOffer.borrower,
                // loanOffer.loanAmount, //Store the loan Amount in wei
                loanOffer.interestRate,
                loanOffer.loanDuration,
                loanOffer.nonce
            )
        ))
        ), signature);
    }

    // function validateSignatureMakePayment(   
    //     bytes calldata signature,
    //     LoanOfferNative calldata loanOffer
    // ) internal pure returns (bool) {
 
    //         return _verifyHashSignature(loanOffer.lender, keccak256(
    //         abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(
    //         abi.encode(
    //             loanOffer.tokenId,
    //             loanOffer.nftContractAddress,
    //             loanOffer.lender,
    //             loanOffer.borrower,
    //             loanOffer.loanAmount, //Store the loan Amount in wei
    //             loanOffer.interestRate,
    //             loanOffer.loanDuration,
    //             loanOffer.nonce
    //         )
    //     ))
    //     ), signature);
    // }

 
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