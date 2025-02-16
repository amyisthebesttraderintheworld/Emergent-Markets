// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title InternalEmergeToken
 * @dev Internal token used within the closed-loop trading system
 * Only the marketplace contract can mint/burn these tokens
 */
contract InternalEmergeToken is ERC20, Ownable, ReentrancyGuard {
    address public marketplace;
    mapping(address => bool) public isParticipant;
    
    event ParticipantAdded(address participant);
    event ParticipantRemoved(address participant);
    event MarketplaceUpdated(address newMarketplace);

    constructor() ERC20("Internal Emerge", "iEMG") Ownable(msg.sender) {
        // Initially, no marketplace is set
    }

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "Only marketplace can perform this action");
        _;
    }

    modifier onlyParticipant() {
        require(isParticipant[msg.sender], "Only participants can perform this action");
        _;
    }

    function setMarketplace(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "Invalid marketplace address");
        marketplace = _marketplace;
        emit MarketplaceUpdated(_marketplace);
    }

    function addParticipant(address participant) external onlyOwner {
        require(!isParticipant[participant], "Already a participant");
        isParticipant[participant] = true;
        emit ParticipantAdded(participant);
    }

    function removeParticipant(address participant) external onlyOwner {
        require(isParticipant[participant], "Not a participant");
        isParticipant[participant] = false;
        emit ParticipantRemoved(participant);
    }

    function mint(address to, uint256 amount) external onlyMarketplace {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyMarketplace {
        _burn(from, amount);
    }

    // Override transfer to ensure only participants can transfer tokens
    function transfer(address to, uint256 amount) public override onlyParticipant returns (bool) {
        require(isParticipant[to], "Recipient must be a participant");
        return super.transfer(to, amount);
    }

    // Override transferFrom to ensure only participants can transfer tokens
    function transferFrom(address from, address to, uint256 amount) public override onlyParticipant returns (bool) {
        require(isParticipant[to], "Recipient must be a participant");
        return super.transferFrom(from, to, amount);
    }
}
