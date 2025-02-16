// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./RealWorldEmergeToken.sol";

/**
 * @title Treasury
 * @dev Manages the real-world token supply based on internal system activities
 * Implements a 100:1 ratio for internal:real-world token minting/burning
 */
contract Treasury is Ownable, ReentrancyGuard, Pausable {
    RealWorldEmergeToken public realWorldToken;
    address public marketplace;
    
    // Ratio of internal tokens to real-world tokens (100:1)
    uint256 public constant INTERNAL_TO_REAL_RATIO = 100;
    
    // Accumulated internal token balance that hasn't triggered a real-world token action
    uint256 private internalTokenAccumulator;
    
    event MarketplaceUpdated(address newMarketplace);
    event RealWorldTokenMinted(uint256 amount);
    event RealWorldTokenBurned(uint256 amount);
    
    constructor(address _realWorldToken) Ownable(msg.sender) {
        realWorldToken = RealWorldEmergeToken(_realWorldToken);
    }
    
    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "Only marketplace can perform this action");
        _;
    }
    
    function setMarketplace(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Invalid marketplace address");
        marketplace = _marketplace;
        emit MarketplaceUpdated(_marketplace);
    }
    
    /**
     * @dev Called by marketplace when internal tokens are minted
     * For every 100 internal tokens, 1 real-world token is minted
     * @param amount The amount of internal tokens minted
     */
    function handleInternalMint(uint256 amount) external onlyMarketplace whenNotPaused nonReentrant {
        internalTokenAccumulator += amount;
        
        uint256 realWorldAmount = internalTokenAccumulator / INTERNAL_TO_REAL_RATIO;
        if (realWorldAmount > 0) {
            internalTokenAccumulator = internalTokenAccumulator % INTERNAL_TO_REAL_RATIO;
            realWorldToken.mint(address(this), realWorldAmount);
            emit RealWorldTokenMinted(realWorldAmount);
        }
    }
    
    /**
     * @dev Called by marketplace when internal tokens are burned
     * For every 100 internal tokens, 1 real-world token is burned
     * @param amount The amount of internal tokens burned
     */
    function handleInternalBurn(uint256 amount) external onlyMarketplace whenNotPaused nonReentrant {
        internalTokenAccumulator += amount;
        
        uint256 realWorldAmount = internalTokenAccumulator / INTERNAL_TO_REAL_RATIO;
        if (realWorldAmount > 0) {
            internalTokenAccumulator = internalTokenAccumulator % INTERNAL_TO_REAL_RATIO;
            realWorldToken.burn(address(this), realWorldAmount);
            emit RealWorldTokenBurned(realWorldAmount);
        }
    }
    
    /**
     * @dev Emergency function to pause all minting/burning operations
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause minting/burning operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Returns the current accumulator value
     */
    function getAccumulatorValue() external view returns (uint256) {
        return internalTokenAccumulator;
    }
}
