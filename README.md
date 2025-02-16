# Emergent Markets Smart Contracts

A decentralized, closed-loop trading system where two agents (Bob and Lisa) interact with an automated marketplace to trade alphanumeric assets using internal Emerge tokens.

## Contracts

- `InternalEmergeToken.sol`: Manages the closed-loop trading system tokens
- `RealWorldEmergeToken.sol`: The public tradable token
- `Treasury.sol`: Controls real-world token supply based on internal activity
- `Marketplace.sol`: Facilitates trading between Bob and Lisa

## Architecture

- Closed-loop trading system where only Bob and Lisa can participate
- Automated marketplace with fixed initial pricing for alphanumeric assets
- 100:1 ratio mechanism for internal to real-world token minting/burning
- Security features including pause functionality and restricted access
