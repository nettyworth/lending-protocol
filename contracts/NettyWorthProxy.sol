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
import "./library/SignatureUtils.sol";

contract NettyWorthProxy is ReentrancyGuard, Initializable {

    using SafeERC20 for IERC20;
    using Address for address;

    address public vault;
    address public loanManager;
    address public receiptContract;
    address public owner;
    ICryptoVault _icryptoVault;
    ILoanManager _iloanManager;
    ReceiptInterface _ireceipts;

     event Loans(
        address indexed lender,
        address nftContract,
        uint256 tokenId);

    mapping (address => mapping (uint256 => bool)) private _nonceUsedForUser;

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
        // _lastNonce = 0;
    }

    function setVault(address _vault) public onlyOwner {
        require(_vault != address(0), "Invalid address");
        vault = _vault;
        _icryptoVault = ICryptoVault(_vault);
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


    // function _depositNftToEscrow(bytes calldata signature, address _contract, uint256 tokenId) internal nonReentrant {
    //     // require(vault != address(0), "Vault address not set");
    //     // require(loanManager != address(0), "Loan manager address not set");
    //     // require(receiptContract != address(0), "Receipt contract address not set");

    //     // Validate the provided signature (server-side validation)
    //     require(SignatureUtils.validateNftDepositSignature(signature, _contract, tokenId, msg.sender), "Invalid nft deposit signature");
    //     // // Get the loans associated with the ERC721 token and borrower
    //     // ILoanManager.Loan memory loan = _iloanManager.getLoan(_contract, tokenId, msg.sender);
    //     // Transfer the specified ERC721 token to the vault
    //     _icryptoVault.deposit(msg.sender,_contract, tokenId);
    //     // // Transfer the ERC20 amount from the borrower to the vault
    //     // IERC20 erc20Token = IERC20(loan.currencyERC20);
    //     // erc20Token.safeTransferFrom(loan.lender, loan.borrower, loan.loanAmount);
    //     // Generate promissory note nft to lender
    //     uint256 receiptIdBorrower = _ireceipts.generateBorrowerReceipt(msg.sender);
    //     _icryptoVault.attachReceiptToNFT(_contract, tokenId, receiptIdBorrower);

    // }


      function _depositNftToEscrowAndERC20ToBorrower(
        address _contract,
        uint256 _tokenId,
        address _currencyERC20,
        address _lender,
        uint256 _loanAmount
        ) internal {
        // require(vault != address(0), "Vault address not set");
        // require(loanManager != address(0), "Loan manager address not set");
        // require(receiptContract != address(0), "Receipt contract address not set");

        // Validate the provided signature (server-side validation)
        // // Get the loans associated with the ERC721 token and borrower
        // ILoanManager.Loan memory loan = _iloanManager.getLoan(_contract, tokenId, msg.sender);
        // Transfer the specified ERC721 token to the vault
        _icryptoVault.deposit(msg.sender,_contract, _tokenId);
        // // Transfer the ERC20 amount from the borrower to the vault
        IERC20 erc20Token = IERC20(_currencyERC20);
        erc20Token.safeTransferFrom(_lender, msg.sender, _loanAmount);
        // Generate promissory note nft to lender
        uint256 receiptIdBorrower = _ireceipts.generateBorrowerReceipt(msg.sender);
        _icryptoVault.attachReceiptToNFT(_contract, _tokenId, receiptIdBorrower);
         uint256 receiptIdLender = _ireceipts.generateLenderReceipt(_lender);
        _icryptoVault.attachReceiptToNFT(_contract, _tokenId, receiptIdLender);

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


    function approveLoan(
        uint256 tokenId,
        address nftContractAddress,
        address erc20TokenAddrss,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 loanDuration,
        address lender,
        address borrower
    ) external nonReentrant {
        require(vault != address(0), "Vault address not set");
        require(loanManager != address(0), "Loan manager address not set");
        require(receiptContract != address(0), "Receipt contract address not set");
        ILoanManager.LoanData memory _data = ILoanManager.LoanData(nftContractAddress,tokenId,borrower,lender,loanAmount,interestRate,loanDuration,erc20TokenAddrss);
     

        ILoanManager.Loan memory loan = _iloanManager.getLoan(
            nftContractAddress,
            tokenId,
            borrower
        );
        //   ILoanManager.Loan memory loan = _iloanManager.getLoan(
         
        require(!loan.isClosed, "Loan offer is closed");
        require(!loan.isApproved, "Loan offer is already approved");

        _iloanManager.createLoan(
            _data._contract,
            _data._tokenId,
            _data._borrower,
            _data._lender,
            _data._loanAmount,
            _data._interestRate,
            _data._loanDuration,
            _data._erc20Token      
        );

        _depositNftToEscrowAndERC20ToBorrower( 
            nftContractAddress,
            tokenId,
            erc20TokenAddrss,
             lender,
             loanAmount
            );

        loan.isApproved =  true ;
        emit Loans( lender, nftContractAddress, tokenId);
    // function makeOffer(
    //     bytes calldata offerSignature,
    //     SignatureUtils.LoanOffer memory _offer
    // ) external nonReentrant {
    //     require(vault != address(0), "Vault address not set");
    //     require(loanManager != address(0), "Loan manager address not set");
    //     require(receiptContract != address(0), "Receipt contract address not set");
    //     require(
    //         SignatureUtils.validateSignatureOffer(
    //             offerSignature,
    //             _offer.tokenId,
    //             _offer.nftContractAddress,
    //             _offer.erc20TokenAddrss,
    //             _offer.loanAmount,
    //             _offer.interestRate,
    //             _offer.loanDuration,
    //             _offer.lender
    //         ),
    //         "Invalid signature"
    //     );

    // }

    // function approveLoan(
    //     bytes calldata acceptOfferSignature,
    //     SignatureUtils.LoanOffer memory _loanOffer
    // ) external nonReentrant {
    //     require(vault != address(0), "Vault address not set");
    //     require(loanManager != address(0), "Loan manager address not set");
    //     require(receiptContract != address(0), "Receipt contract address not set");
    //     require(!_nonceUsedForUser[_loanOffer.lender][_loanOffer.lenderNonce], "Lender offer nonce invalid");
    //     _nonceUsedForUser[_loanOffer.lender][_loanOffer.lenderNonce] = true;
      
    //     require(
    //         SignatureUtils.validateSignatureApprovalOffer(
    //             acceptOfferSignature,
    //             _loanOffer.tokenId,
    //             _loanOffer.nftContractAddress,
    //             _loanOffer.erc20TokenAddrss,
    //             _loanOffer.loanAmount,
    //             _loanOffer.interestRate,
    //             _loanOffer.loanDuration,
    //             _loanOffer.lender,
    //             _loanOffer.lenderNonce,
    //             _loanOffer.borrower
    //         ),
    //         "Invalid signature"
    //     );

    //     ILoanManager.Loan memory loan = _iloanManager.getLoan(
    //         _loanOffer.nftContractAddress,
    //         _loanOffer.tokenId,
    //         _loanOffer.borrower
    //     );
    //     require(!loan.isClosed, "Loan offer is closed");
    //     require(!loan.isApproved, "Loan offer is already approved");

    //     _iloanManager.createLoan(
    //         _loanOffer.nftContractAddress,
    //         _loanOffer.tokenId,
    //         _loanOffer.borrower,
    //         _loanOffer.lender,
    //         _loanOffer.loanAmount,
    //         _loanOffer.interestRate,
    //         _loanOffer.loanDuration,
    //         _loanOffer.erc20TokenAddrss,
    //         _loanOffer.lenderNonce
    //     );

    //     _depositNftToEscrowAndERC20ToBorrower( 
    //         _loanOffer.nftContractAddress,
    //         _loanOffer.tokenId,
    //         _loanOffer.erc20TokenAddrss,
    //          _loanOffer.lender,
    //          _loanOffer.loanAmount
    //         );


        // // Transfer the ERC20 amount from the borrower to the vault
        // IERC20 erc20Token = IERC20(loan.currencyERC20);

        // erc20Token.safeTransferFrom(
        //     loan.lender,
        //     loan.borrower,
        //     loan.loanAmount
        // );
        //  uint256 receiptLender =_ireceipts.generateLenderReceipt(loan.lender);
    }

    // function generateLenderReceipt(address lender) public returns (uint256) {
    //     require(_ireceipts.open(), "Contract closed");
    //     uint256 receiptIdLender = _ireceipts.generateReceipts(lender);
    //     return receiptIdLender;
    // }

    // Function called by lender

    function payLoan(
        uint256 _receiptId,
        address _nftCollateralContract,
        uint256 _tokenId
    )
        external
        // address _lender
        nonReentrant
    {
        require(_ireceipts.tokenExist(_receiptId), "Receipt does not exist");
        address lender = _ireceipts.ownerOf(_receiptId);  // borrower address 
        // address borrower = _ireceipts.ownerOf(receiptId + 1);
        ILoanManager.Loan memory loan = _iloanManager.getLoan(
            _nftCollateralContract,
            _tokenId,
            lender
        );

          uint256 _loanId = _iloanManager.getLoanId(
            _nftCollateralContract,
            _tokenId,
            lender
        );
        require(loan.isApproved, "Loan offer not approved");
        require(!loan.isClosed, "Loan is closed");
        _iloanManager.getPayoffAmount(_loanId);
        // Transfer the ERC20 amount from the borrower to the vault
        IERC20 erc20Token = IERC20(loan.currencyERC20);
        // erc20Token.safeTransferFrom(msg.sender, vault, loan.loanAmount);

        require(erc20Token.balanceOf(msg.sender) >=  loan.loanAmount,"Insufficent balance to payloan");
        erc20Token.safeTransferFrom(msg.sender, loan.lender, loan.loanAmount);

        _icryptoVault.withdraw(_nftCollateralContract,_tokenId ,loan.borrower);

        loan.isClosed = true;

        _icryptoVault.unattachReceiptToNFT(_nftCollateralContract, _tokenId, _receiptId);

        _ireceipts.burnReceipt(_receiptId);
        
        _iloanManager.deleteLoan(_nftCollateralContract, _tokenId, loan.borrower);

        //  uint256 receiptIdLender = _ireceipts.generateLenderReceipt(msg.sender);
        // _icryptoVault.attachReceiptToNFT(_contract, _tokenId, receiptIdLender);

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


}



