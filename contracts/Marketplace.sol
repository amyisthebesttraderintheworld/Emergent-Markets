// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./InternalEmergeToken.sol";
import "./Treasury.sol";

/**
 * @title Marketplace
 * @dev Facilitates trading of alphanumeric assets between Bob and Lisa
 * Manages internal token minting/burning and coordinates with Treasury
 */
contract Marketplace is Ownable, ReentrancyGuard, Pausable {
    InternalEmergeToken public internalToken;
    Treasury public treasury;
    
    // Fixed price for all alphanumeric assets (can be adjusted by owner)
    uint256 public assetPrice;
    
    // Mapping to track ownership of alphanumeric assets
    mapping(address => mapping(bytes1 => uint256)) public assetBalances;
    
    // Trading volume tracking
    mapping(bytes1 => uint256) public assetVolume;
    
    event AssetPriceUpdated(uint256 newPrice);
    event AssetTraded(address indexed trader, bytes1 indexed asset, bool isBuy, uint256 amount);
    event InternalTokensMinted(address indexed to, uint256 amount);
    event InternalTokensBurned(address indexed from, uint256 amount);
    
    constructor(
        address _internalToken,
        address _treasury,
        uint256 initialAssetPrice
    ) Ownable(msg.sender) {
        internalToken = InternalEmergeToken(_internalToken);
        treasury = Treasury(_treasury);
        assetPrice = initialAssetPrice;
    }
    
    /**
     * @dev Allows owner to adjust the fixed asset price
     */
    function setAssetPrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Price must be positive");
        assetPrice = _newPrice;
        emit AssetPriceUpdated(_newPrice);
    }
    
    /**
     * @dev Buy alphanumeric assets using internal tokens
     * @param asset The asset to buy (A-Z, 0-9)
     * @param amount The amount to buy
     */
    function buyAsset(bytes1 asset, uint256 amount) external whenNotPaused nonReentrant {
        require(isValidAsset(asset), "Invalid asset");
        require(amount > 0, "Amount must be positive");
        
        uint256 totalCost = amount * assetPrice;
        
        // Burn internal tokens from buyer
        internalToken.burn(msg.sender, totalCost);
        emit InternalTokensBurned(msg.sender, totalCost);
        
        // Update asset balance and volume
        assetBalances[msg.sender][asset] += amount;
        assetVolume[asset] += amount;
        
        // Notify treasury of internal token burning
        treasury.handleInternalBurn(totalCost);
        
        emit AssetTraded(msg.sender, asset, true, amount);
    }
    
    /**
     * @dev Sell alphanumeric assets to receive internal tokens
     * @param asset The asset to sell (A-Z, 0-9)
     * @param amount The amount to sell
     */
    function sellAsset(bytes1 asset, uint256 amount) external whenNotPaused nonReentrant {
        require(isValidAsset(asset), "Invalid asset");
        require(amount > 0, "Amount must be positive");
        require(assetBalances[msg.sender][asset] >= amount, "Insufficient asset balance");
        
        uint256 totalPayment = amount * assetPrice;
        
        // Update asset balance and volume
        assetBalances[msg.sender][asset] -= amount;
        assetVolume[asset] += amount;
        
        // Mint internal tokens to seller
        internalToken.mint(msg.sender, totalPayment);
        emit InternalTokensMinted(msg.sender, totalPayment);
        
        // Notify treasury of internal token minting
        treasury.handleInternalMint(totalPayment);
        
        emit AssetTraded(msg.sender, asset, false, amount);
    }
    
    /**
     * @dev Check if an asset is valid (A-Z, 0-9)
     */
    function isValidAsset(bytes1 asset) public pure returns (bool) {
        return (
            (asset >= 0x30 && asset <= 0x39) || // 0-9
            (asset >= 0x41 && asset <= 0x5A)    // A-Z
        );
    }
    
    /**
     * @dev Get asset balance for a specific address
     */
    function getAssetBalance(address owner, bytes1 asset) external view returns (uint256) {
        return assetBalances[owner][asset];
    }
    
    /**
     * @dev Get trading volume for a specific asset
     */
    function getAssetVolume(bytes1 asset) external view returns (uint256) {
        return assetVolume[asset];
    }
    
    /**
     * @dev Emergency function to pause all trading
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause trading
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
