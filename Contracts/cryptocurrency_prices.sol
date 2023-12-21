// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CrosschainTokenPriceComparison {

    // Define supported tokens and their addresses
    address public constant ETH = 0x0000000000000000000000000000000000000000;
    address public constant BTC = 0x2260FaC50802287Fa5FA985B77b558f6b1AC3903;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;


    // Define supported chains and their IDs
    uint256 public constant ETH_CHAIN_ID = 1;
    uint256 public constant POLY_CHAIN_ID = 137;
    uint256 public constant AVALANCHE_CHAIN_ID = 43114;

    // Mapping storing latest token prices for each chain
    mapping(address => mapping(uint256 => uint256)) public latestPrices;

    // Mapping storing Chainlink oracle addresses for each token and chain
    mapping(address => mapping(uint256 => address)) public priceFeedOracles;

    mapping (address => uint8) public  tokenDecimals;

    // Function to register an oracle address for a specific token and chain
    function registerPriceFeedOracle(address token, uint256 chainId, address oracleAddress) public {
        priceFeedOracles[token][chainId] = oracleAddress;
    }

    // Function to update the latest price for a specific token and chain
    function updatePrice(address token, uint256 chainId) public {
        AggregatorV3Interface oracle = AggregatorV3Interface(priceFeedOracles[token][chainId]);
        (, int256 latestPrice, , , ) = oracle.latestRoundData();
        latestPrices[token][chainId] = uint256(latestPrice);
    }

    // Function to get the latest price for a specific token and chain
    function getLatestPrice(address token, uint256 chainId) public view returns (uint256) {
        return latestPrices[token][chainId];
    }

    // Additional functions (optional):
    // * Get price data in a specific format (e.g., with decimals)
    // * Calculate price difference between chains
    // * Fetch historical price data
    // * Integrate with Chainlink Keepers for automatic updates

    // Function to retrieve decimals
    function getDecimalsForToken(address token) public returns (uint8 decimals) {
        // Check if decimals are stored within the contract
        decimals = tokenDecimals[token]; // Assuming a mapping for stored decimals
        if (decimals > 0) {
            return decimals;
        }

        // Attempt to retrieve decimals from the token contract
        try ERC20(token).decimals() returns (uint8 _decimals) {
            decimals = _decimals;
            tokenDecimals[token] = decimals; // Cache for future calls
            return decimals;
        } catch {
            // Handle errors (e.g., token doesn't support IERC20 or call failed)
            return 18; // Default to 18 decimals if retrieval fails
        }
    }

    // Function to get the latest price in decimal format
    function getLatestPriceInDecimals(address token, uint256 chainId)
        public
        returns (uint256 decimals, uint256 priceWithDecimals)
    {
        AggregatorV3Interface oracle = AggregatorV3Interface(priceFeedOracles[token][chainId]);
        (, int256 price, , , ) = oracle.latestRoundData();

        // Retrieve decimals from a reliable source
        // (e.g., a trusted contract or hardcoded based on token standard)
        uint256 decimals_ = getDecimalsForToken(token); // Adjust this function call accordingly

        // Handle potential overflow
        if (price < 0 || decimals_ > 18) {
            revert("Price overflow or invalid decimals");
        } else {
            priceWithDecimals = uint256(price) * 10**decimals_;
        }

        return (decimals_, priceWithDecimals);
    }

    // Function to calculate price difference between chains, ensuring equal decimals and handling potential overflow
    function calculatePriceDifference(address token, uint256 chainId1, uint256 chainId2)
        public
        returns (int256 priceDifference)
    {
        (uint256 decimals1, uint256 price1WithDecimals) = getLatestPriceInDecimals(token, chainId1);
        (uint256 decimals2, uint256 price2WithDecimals) = getLatestPriceInDecimals(token, chainId2);

        // Ensure decimals match for accurate comparison
        require(decimals1 == decimals2, "Decimals must be equal for comparison");

        // Calculate price difference, handling potential overflow
        if (price1WithDecimals > price2WithDecimals) {
            priceDifference = int256(price1WithDecimals) - int256(price2WithDecimals);
        } else {
            priceDifference = int256(price2WithDecimals) - int256(price1WithDecimals);
        }

        return priceDifference;
    }

    // Remember to add error handling and security considerations
}