// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICryptoVault.sol";
import "./interfaces/ILoanManager.sol";
import "./interfaces/IReceipts.sol";

contract NettyWorthProxy is ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public vault;
    address public loanManager;
    address public receiptContract;
    address public secret;
    address public owner;
    uint256 _lastNonce;
    CryptoVaultInterface _icryptoVault;
    ILoanManager _iloanManager;
    ReceiptInterface _ireceipts;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function initialize(
        address _vault,
        address _loanManager,
        address _receiptContract
    ) external initializer {
        owner = msg.sender;
        setVault(_vault);
        setLoanManager(_loanManager);
        setReceiptContract(_receiptContract);
        _lastNonce = 0;
    }

    function setSigner(address _secret) external onlyOwner {
        require(_secret != address(0), "200:ZERO_ADDRESS");
        secret = _secret;
    }

    function setVault(address _vault) public onlyOwner {
        require(_vault != address(0), "Invalid address");
        vault = _vault;
        _icryptoVault = CryptoVaultInterface(_vault);
    }

    function setLoanManager(address _loanManager) public onlyOwner {
        require(_loanManager != address(0), "Invalid address");
        loanManager = _loanManager;
        _iloanManager = ILoanManager(loanManager);
    }

    function setReceiptContract(address _receiptContract) public onlyOwner {
        require(_receiptContract != address(0), "Invalid address");
        receiptContract = _receiptContract;
        _ireceipts = ReceiptInterface(receiptContract);
    }

    function depositToEscrow(
        bytes calldata signature,
        address _contract,
        uint256 tokenId
    ) external nonReentrant {
        require(vault != address(0), "Vault address not set");
        require(loanManager != address(0), "Loan manager address not set");
        require(
            receiptContract != address(0),
            "Receipt contract address not set"
        );

        // Validate the provided signature (server-side validation)
        require(
            validateSignature(signature, _contract, tokenId, msg.sender),
            "Invalid signature"
        );

        // Transfer the specified ERC721 token to the vault
        IERC721 erc721Token = IERC721(_contract);
        erc721Token.safeTransferFrom(msg.sender, vault, tokenId);
        uint256 receiptIdLender = _ireceipts.generateBorrowerReceipt(
            msg.sender
        );
        _icryptoVault.attachReceiptToNFT(_contract, tokenId, receiptIdLender);
    }

    function claimFromEscrow(
        uint256 tokenId,
        address _contract
    )
        external
        // uint256 _receiptId
        nonReentrant
    {
        require(vault != address(0), "Vault address not set");
        require(loanManager != address(0), "Loan manager address not set");
        require(
            receiptContract != address(0),
            "Receipt contract address not set"
        );

        // Verify if the ERC721 token exists in the vault
        IERC721 erc721Token = IERC721(_contract);
        require(
            erc721Token.ownerOf(tokenId) == vault,
            "Token does not exist in the vault"
        );

        // Get the loans associated with the ERC721 token and borrower
        ILoanManager.Loan memory loan = _iloanManager.getLoan(
            _contract,
            tokenId,
            msg.sender
        );

        require(loan.isClosed, "Loan is not closed");

        // Transfer the ERC721 token back to the borrower
        //_iloanManager.burnReceipt(receiptId);
        erc721Token.safeTransferFrom(vault, msg.sender, tokenId);
    }

    function makeOffer(
        bytes calldata signature,
        uint256 tokenId,
        address _contract,
        address _erc20Token,
        uint256 _loanAmount,
        uint256 _interestRate,
        uint256 _loanDuration
    ) external nonReentrant {
        require(vault != address(0), "Vault address not set");
        require(loanManager != address(0), "Loan manager address not set");
        require(
            receiptContract != address(0),
            "Receipt contract address not set"
        );
        require(
            validateSignatureOffer(
                signature,
                tokenId,
                _contract,
                _erc20Token,
                _loanAmount,
                _interestRate,
                _loanDuration,
                msg.sender
            ),
            "Invalid signature"
        );
        IERC20 erc20Token = IERC20(_erc20Token);
        erc20Token.approve(address(this), _loanAmount);
    }

    function approveLoan(
        bytes calldata signature,
        uint256 _tokenId,
        address _contract,
        address _erc20Token,
        uint256 _loanAmount,
        uint256 _interestRate,
        uint256 _loanDuration,
        address _lender,
        uint256 _nonce
    ) external nonReentrant {
        require(vault != address(0), "Vault address not set");
        require(loanManager != address(0), "Loan manager address not set");
        require(
            receiptContract != address(0),
            "Receipt contract address not set"
        );
        require(_lastNonce < _nonce, "New signature is required");
        require(
            validateApprovalOffer(
                signature,
                _tokenId,
                _contract,
                _erc20Token,
                _loanAmount,
                _interestRate,
                _loanDuration,
                _lender,
                _nonce,
                msg.sender
            ),
            "Invalid signature"
        );

        ILoanManager.Loan memory loan = _iloanManager.getLoan(
            _contract,
            _tokenId,
            msg.sender
        );
        require(!loan.isClosed, "Loan offer is closed");
        require(!loan.isApproved, "Loan offer is already approved");

        _iloanManager.createLoan(
            _contract,
            _tokenId,
            msg.sender,
            _lender,
            _loanAmount,
            _interestRate,
            _loanDuration,
            _erc20Token,
            _nonce
        );

        // // Transfer the ERC20 amount from the borrower to the vault
        // IERC20 erc20Token = IERC20(loan.currencyERC20);

        // erc20Token.safeTransferFrom(
        //     loan.lender,
        //     loan.borrower,
        //     loan.loanAmount
        // );
        //  uint256 receiptLender = generateLenderReceipt(loan.lender);
    }

    function generateLenderReceipt(address lender) public returns (uint256) {
        require(_ireceipts.open(), "Contract closed");
        uint256 receiptIdLender = _ireceipts.generateReceipts(lender);
        return receiptIdLender;
    }

    function payLoan(
        uint256 receiptId,
        address _contract,
        uint256 _tokenId
    )
        external
        // address _lender
        nonReentrant
    {
        require(_ireceipts.tokenExist(receiptId), "Receipt does not exist");
        address lender = _ireceipts.ownerOf(receiptId);
        // address borrower = _ireceipts.ownerOf(receiptId + 1);
        ILoanManager.Loan memory loan = _iloanManager.getLoan(
            _contract,
            _tokenId,
            lender
        );
        require(loan.isApproved, "Loan offer not approved");
        require(!loan.isClosed, "Loan is closed");

        // Transfer the ERC20 amount from the borrower to the vault
        IERC20 erc20Token = IERC20(loan.currencyERC20);
        erc20Token.safeTransferFrom(msg.sender, vault, loan.loanAmount);

        //_iloanManager.updateLoan(_contract, _tokenId, lender, loan);
    }

    function claimToken(
        uint256 receiptId,
        address _contract,
        uint256 _tokenId
    ) external nonReentrant {
        require(_ireceipts.tokenExist(receiptId), "Receipt does not exist");
        address borrower = _ireceipts.ownerOf(receiptId);
        ILoanManager.Loan memory loan = _iloanManager.getLoan(
            _contract,
            _tokenId,
            borrower
        );
        require(loan.isApproved, "Loan offer not approved");
        require(loan.isClosed, "Loan is not closed");

        // Transfer the ERC721 token back to the borrower from the vault
        // IERC721 erc721Token = IERC721(_contract);

        //erc721Token.burn(_tokenId);
        // _ireceipts.closeReceipt(receiptId);
    }

    function claimERC20(
        uint256 receiptId,
        address _contract,
        uint256 _tokenId
    ) external nonReentrant {
        //require(_ireceipts.exists(receiptId), "Receipt does not exist");
        address lender = _ireceipts.ownerOf(receiptId);
        ILoanManager.Loan memory loan = _iloanManager.getLoan(
            _contract,
            _tokenId,
            lender
        );
        require(loan.isApproved, "Loan offer not approved");
        require(loan.isClosed, "Loan is not closed");

        // Transfer the ERC721 token back to the borrower from the vault
        // IERC721 erc721Token = IERC721(_contract);
        // erc721Token.burn(_tokenId);

        // Close the receipt
        // _ireceipts.closeReceipt(receiptId);
    }

    function validateSignature(
        bytes calldata signature,
        address _contract,
        uint256 tokenId,
        address _sender
    ) public view returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(abi.encode(_contract, tokenId, _sender));
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function validateSignatureOffer(
        bytes calldata signature,
        uint256 tokenId,
        address _contract,
        address _erc20Token,
        uint256 _loanAmount,
        uint256 _interestRate,
        uint256 _loanDuration,
        address _signer
    ) internal view returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(
            abi.encode(
                tokenId,
                _contract,
                _erc20Token,
                _loanAmount,
                _interestRate,
                _loanDuration,
                _signer
            )
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function validateApprovalOffer(
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
    ) internal view returns (bool) {
        // Pack the payload
        bytes32 freshHash = keccak256(
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
        );
        // Get the packed payload hash
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        // Verify if the fresh hash is signed with the provided signature
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyHashSignature(
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
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
