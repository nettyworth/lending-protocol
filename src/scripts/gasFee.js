const { ethers } = require("ethers");
const axios = require("axios");
require("dotenv").config();
const { INFURA_API_KEY, INFURA_API_KEY_SECRET } = process.env;

async function getGasFees(chainId) {
  const Auth = Buffer.from(
    INFURA_API_KEY + ":" + INFURA_API_KEY_SECRET,
  ).toString("base64");

  try {
    const { data } = await axios.get(
      `https://gas.api.infura.io/networks/${chainId}/suggestedGasFees`,
      {
        headers: {
          Authorization: `Basic ${Auth}`,
        },
      },
    );
    return data;
  } catch (error) {
    console.log("Error fetching gas fees:", error);
    throw error;
  }
}

// Estimate gas for the transfer function
const roundToDecimalPlaces = (value, decimals) => {
  const factor = 10 ** decimals;
  return Math.round(value * factor) / factor;
};

async function fetchGasFees() {
  try {
    const gasFees = await getGasFees(1); // Mainnet chain ID is 1=ETH
    console.log({ gasFees });
    const maxFeePerGasString = roundToDecimalPlaces(
      gasFees.medium.suggestedMaxFeePerGas,
      9,
    ).toString();
    const maxFeePerGasInGwei = ethers.parseUnits(maxFeePerGasString, "gwei");
    const maxPriorityFeePerGasString = roundToDecimalPlaces(
      gasFees.medium.suggestedMaxPriorityFeePerGas,
      9,
    ).toString();
    const maxPriorityFeePerGasInGwei = ethers.parseUnits(
      maxPriorityFeePerGasString,
      "gwei",
    );

    return { maxFeePerGasInGwei, maxPriorityFeePerGasInGwei };
  } catch (error) {
    console.error("Failed to fetch and export gas fees:", error);
  }
}
fetchGasFees();
// export { fetchGasFees };
