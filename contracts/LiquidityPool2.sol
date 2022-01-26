// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.0;

import "./UnderlyingToken.sol";
import "./LpToken.sol";
import "./GovernanceToken.sol";

//More advanced distribution mechanism with a fixed amount of reward per block
//for the whole contract
//WIP
contract LiquidityPool2 is LpToken {
    struct Checkpoint {
        uint256 blockNumber;
        uint256 avgTotalBalance;
    }

    mapping(address => Checkpoint) public checkpoints;
    Checkpoint public globalCheckpoint;

    uint256 public constant REWARD_PER_BLOCK = 1000 * 10**18;

    UnderlyingToken public underlyingToken;
    GovernanceToken public governanceToken;
    uint256 public genesisBlock;

    constructor(address _underlyingToken, address _governanceToken) {
        underlyingToken = UnderlyingToken(_underlyingToken);
        governanceToken = GovernanceToken(_governanceToken);
        globalCheckpoint.blockNumber = block.number;
        genesisBlock = block.number;
    }

    function deposit(uint256 amount) external {
        globalCheckpoint.avgTotalBalance = _getAvgTotalBalance();
        globalCheckpoint.blockNumber = block.number;

        _distributeRewards(msg.sender);

        underlyingToken.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        globalCheckpoint.avgTotalBalance = _getAvgTotalBalance();
        checkpoints[msg.sender].avgTotalBalance = globalCheckpoint
            .avgTotalBalance;
        checkpoints[msg.sender].blockNumber = block.number;
    }

    function withdraw(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "not enough lp token");

        globalCheckpoint.avgTotalBalance = _getAvgTotalBalance();
        globalCheckpoint.blockNumber = block.number;

        _distributeRewards(msg.sender);

        checkpoints[msg.sender].avgTotalBalance = globalCheckpoint
            .avgTotalBalance;
        checkpoints[msg.sender].blockNumber = block.number;

        underlyingToken.transfer(msg.sender, amount);
        _burn(msg.sender, amount);

        globalCheckpoint.avgTotalBalance = _getAvgTotalBalance();
        checkpoints[msg.sender].avgTotalBalance = globalCheckpoint
            .avgTotalBalance;
        checkpoints[msg.sender].blockNumber = block.number;
    }

    function _getAvgTotalBalance() public view returns (uint256) {
        if (block.number - genesisBlock == 0) {
            return totalSupply();
        }
        return
            (globalCheckpoint.avgTotalBalance *
                (globalCheckpoint.blockNumber - genesisBlock) +
                totalSupply() *
                (block.number - globalCheckpoint.blockNumber)) /
            (block.number - genesisBlock);
    }

    function _distributeRewards(address beneficiary) internal {
        Checkpoint storage userCheckpoint = checkpoints[beneficiary];
        if (block.number - userCheckpoint.blockNumber > 0) {
            uint256 avgTotalBalanceRewardPeriod = (globalCheckpoint
                .avgTotalBalance *
                globalCheckpoint.blockNumber -
                userCheckpoint.avgTotalBalance *
                userCheckpoint.blockNumber) /
                (block.number - userCheckpoint.blockNumber);
            if (avgTotalBalanceRewardPeriod > 0) {
                uint256 distributionAmount = (balanceOf(beneficiary) *
                    (block.number - userCheckpoint.blockNumber) *
                    REWARD_PER_BLOCK) / avgTotalBalanceRewardPeriod;
                governanceToken.mint(beneficiary, distributionAmount);
            }
        }
    }
}
