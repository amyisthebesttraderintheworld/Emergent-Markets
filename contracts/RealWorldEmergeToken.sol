// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title RealWorldEmergeToken
 * @dev Public ERC20 token that can be traded on external markets
 * Supply is controlled by the Treasury contract based on internal system activity
 */
contract RealWorldEmergeToken is ERC20, Ownable, ReentrancyGuard {
    address public treasury;
    
    event TreasuryUpdated(address newTreasury);

    constructor() ERC20("Real World Emerge", "EMG") Ownable(msg.sender) {
        // Initially, no treasury is set
    }

    modifier onlyTreasury() {
        require(msg.sender == treasury, "Only treasury can perform this action");
        _;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid treasury address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /**
     * @dev Mints new tokens. Can only be called by the treasury contract.
     * This is triggered when internal system activity requires new real-world tokens.
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyTreasury {
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens. Can only be called by the treasury contract.
     * This is triggered when internal system activity requires burning real-world tokens.
     * @param from Address from which to burn tokens
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 amount) external onlyTreasury {
        _burn(from, amount);
    }
}
