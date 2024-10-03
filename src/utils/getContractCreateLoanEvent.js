const { ethers } = require('ethers');

const loanContractABI = require('../../src/artifacts/src/contracts/LoanManager.sol/LoanManager.json');

const loanContractAddress = '0x86240D27E698f6dA336E060a527441879de39c53';

const provider = new ethers.JsonRpcProvider(
  'https://sepolia.infura.io/v3/3df44251533e4df3b1f0407d6ec4f34b'
);

const loanContract = new ethers.Contract(
  loanContractAddress,
  loanContractABI.abi,
  provider
);

let Loans = [];
const getevents = async () => {
  try {
    const currentBlock = await provider.getBlockNumber();
    console.log('Current Block Number:', currentBlock);

    const loanCreatedEvents = await loanContract.queryFilter(
      'LoanCreated',
      0,
      currentBlock
    );

    loanCreatedEvents.forEach((event) => {
      const loanDetails = {
        loanId: event.args.loanId.toString(),
        nftContract: event.args.nftContract,
        tokenId: event.args.tokenId.toString(),
        borrower: event.args.borrower,
        lender: event.args.lender,
        loanAmount: event.args.loanAmount.toString(),
        aprBasisPoints: event.args.aprBasisPoints.toString(),
        loanDuration: event.args.loanDuration.toString(),
        erc20Address: event.args.erc20Address,
        loanInitialTime: event.args.loanInitialTime.toString(),
        isPaid: event.args.isPaid,
        isClosed: event.args.isClosed,
        isApproved: event.args.isApproved,
      };
      Loans.push(loanDetails);
      //   console.log("Loan Created Event:");
      //   console.log("Loan ID: ", event.args.loanId.toString());
      //   console.log("NFT Contract: ", event.args.nftContract);
      //   console.log("Token ID: ", event.args.tokenId.toString());
      //   console.log("Borrower: ", event.args.borrower);
      //   console.log("Lender: ", event.args.lender);
      //   console.log("Loan Amount: ", event.args.loanAmount.toString());
      //   console.log("APR (Basis Points): ", event.args.aprBasisPoints.toString());
      //   console.log("Loan Duration: ", event.args.loanDuration.toString());
      //   console.log("Currency ERC20 Address: ", event.args.erc20Address);
      //   console.log("Loan Initial Time: ", event.args.loanInitialTime);
      //   console.log("Is Paid: ", event.args.isPaid);
      //   console.log("Is Closed: ", event.args.isClosed);
      //   console.log("Is Approved: ", event.args.isApproved);
      //   console.log("-----");
    });
  } catch (error) {
    console.error('Error fetching events:', error);
  }
};

async function main() {
  await getevents();
  console.log('LoansCount', Loans.length);
  console.log('Loans', Loans);
}

main();
