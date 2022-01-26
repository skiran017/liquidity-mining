// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.0;

import "./LpToken.sol";
import "./UnderlyingToken.sol";
import "./GovernanceToken.sol";

//Basic LiquidityPool contract
contract LiquidityPool is LpToken {
    mapping(address => uint256) public checkpoints;
    UnderlyingToken public underlyingToken;
    GovernanceToken public governanceToken;
    //investors will earn 1 governancce token per block for each underlying token which is invested
    uint256 public constant REWARD_PER_BLOCK = 1;

    constructor(address _underlyingToken, address _governanceToken) {
        underlyingToken = UnderlyingToken(_underlyingToken);
        governanceToken = GovernanceToken(_governanceToken);
    }

    //amount of underlying token investor wants to deposit
    function deposit(uint256 amount) external {
        if (checkpoints[msg.sender] == 0) {
            checkpoints[msg.sender] = block.number;
        }
        _distributeRewards(msg.sender);
        underlyingToken.transferFrom(msg.sender, address(this), amount);
        // underlyingToken.transfer(msg.sender,address(this), amount);
        _mint(msg.sender, amount);
    }

    //amount of LP token to withdraw
    function withdraw(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "not enough LP tokens");
        _distributeRewards(msg.sender);
        underlyingToken.transfer(msg.sender, amount);
        _burn(msg.sender, amount);
    }

    function _distributeRewards(address beneficiary) internal {
        uint256 checkpoint = checkpoints[beneficiary];
        if (block.number - checkpoint > 0) {
            uint256 distributionAmount = balanceOf(beneficiary) *
                (block.number - checkpoint) *
                REWARD_PER_BLOCK;
            governanceToken.mint(beneficiary, distributionAmount);
            checkpoints[beneficiary] = block.number;
        }
    }
}
